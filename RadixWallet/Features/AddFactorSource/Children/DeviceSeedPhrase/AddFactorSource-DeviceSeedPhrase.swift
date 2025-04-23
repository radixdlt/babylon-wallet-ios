import ComposableArchitecture
import Sargon

// MARK: - AddFactorSource.DeviceSeedPhrase
extension AddFactorSource {
	@Reducer
	struct DeviceSeedPhrase: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			@Shared(.deviceMnemonicBuilder) var deviceMnemonicBuilder

			var grid: ImportMnemonicGrid.State
			var isEnteringCustomSeedPhrase: Bool = false

			var confirmButtonControlState: ControlState {
				switch status {
				case .incomplete, .invalid:
					.disabled
				case .valid:
					.enabled
				}
			}

			@Presents
			var destination: Destination.State? = nil

			init(mnemonic: Mnemonic) {
				grid = .init(mnemonic: mnemonic)
			}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Hashable {
			case onFirstAppear
			case confirmButtonTapped
			case enterCustomSeedPhraseButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Hashable {
			case grid(ImportMnemonicGrid.Action)
		}

		enum InternalAction: Sendable, Equatable {
			case factorAlreadyInUse
		}

		enum DelegateAction: Sendable, Hashable {
			case completed(withCustomSeedPhrase: Bool)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case factorAlreadyInUseAlert(AlertState<Action.FactorAlreadyInUseAlert>)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case factorAlreadyInUseAlert(FactorAlreadyInUseAlert)

				enum FactorAlreadyInUseAlert: Sendable, Hashable {
					case close
				}
			}

			var body: some ReducerOf<Self> {
				EmptyReducer()
			}
		}

		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Scope(state: \.grid, action: \.child.grid) {
				ImportMnemonicGrid()
			}
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .onFirstAppear:
				state.$deviceMnemonicBuilder.withLock { builder in
					builder = builder.generateNewMnemonic()
				}
				if let mnemonic = try? Mnemonic(words: state.deviceMnemonicBuilder.getWords()) {
					state.grid = .init(mnemonic: mnemonic)
				}
				return .none
			case .confirmButtonTapped:
				let isEnteringCustomSeedPhrase = state.isEnteringCustomSeedPhrase
				if isEnteringCustomSeedPhrase {
					state.$deviceMnemonicBuilder.withLock { builder in
						if let builderWithMnemonic = try? builder.createMnemonicFromWords(words: state.completedWords.map(\.word)) {
							builder = builderWithMnemonic
						}
					}
				}
				let factorSourceId = state.deviceMnemonicBuilder.getFactorSourceId()
				return .run { send in
					let isInUse = try await SargonOs.shared.isFactorSourceAlreadyInUse(factorSourceId: factorSourceId)
					if isInUse {
						await send(.internal(.factorAlreadyInUse))
					} else {
						await send(.delegate(.completed(withCustomSeedPhrase: isEnteringCustomSeedPhrase)))
					}
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			case .enterCustomSeedPhraseButtonTapped:
				state.grid = .init(count: .twentyFour, isWordCountFixed: true)
				state.isEnteringCustomSeedPhrase = true
				return .none
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case .factorAlreadyInUse:
				state.destination = Destination.factorAlreadyInUseState
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case .factorAlreadyInUseAlert(.close):
				state.destination = nil
				return .none
			}
		}
	}
}

private extension AddFactorSource.DeviceSeedPhrase.State {
	var mnemonicWithPassphrase: MnemonicWithPassphrase? {
		guard let mnemonic = try? Mnemonic(words: completedWords) else {
			return nil
		}

		return .init(mnemonic: mnemonic)
	}

	/// An enum describing the different errors that can take place from user's input.
	enum Status: Sendable, Hashable {
		/// User hasn't entered every word yet.
		case incomplete

		/// User has entered every word but a Mnemonic cannot be built from it (checksum fails).
		case invalid

		/// The entered mnemonic is complete (checksum succeeds)
		case valid(MnemonicWithPassphrase)
	}

	var status: Status {
		if !isComplete {
			.incomplete
		} else if let mnemonicWithPassphrase {
			.valid(mnemonicWithPassphrase)
		} else {
			.invalid
		}
	}

	var isComplete: Bool {
		completedWords.count == grid.words.count
	}

	var completedWords: [BIP39Word] {
		grid.words.compactMap(\.completeWord)
	}
}

extension AddFactorSource.DeviceSeedPhrase.Destination {
	static let factorAlreadyInUseState: State = .factorAlreadyInUseAlert(.init(
		title: {
			TextState("Factor Already In Use")
		},
		actions: {
			ButtonState(role: .cancel, action: .close) {
				TextState("Close")
			}
		}
	))
}
