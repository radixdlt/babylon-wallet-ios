import ComposableArchitecture
import Sargon

// MARK: - AddFactorSource.InputSeedPhrase
extension AddFactorSource {
	@Reducer
	struct InputSeedPhrase: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			@Shared(.mnemonicBuilder) var mnemonicBuilder

			var grid: ImportMnemonicGrid.State!
			var isEnteringCustomSeedPhrase: Bool = false
			var context: Context
			var bip39Passphrase: String = ""
			var advancedModeEnabled: Bool = false

			let hasPassphrase: Bool
			let factorSourceKind: FactorSourceKind

			var confirmButtonControlState: ControlState {
				switch grid.status {
				case .incomplete, .invalid:
					.disabled
				case .valid:
					.enabled
				}
			}

			@Presents
			var destination: Destination.State? = nil

			init(context: Context, factorSourceKind: FactorSourceKind) {
				self.context = context
				self.factorSourceKind = factorSourceKind
				switch context {
				case .newFactorSource:
					hasPassphrase = false
					$mnemonicBuilder.withLock { builder in
						builder = builder.generateNewMnemonic()
					}

					let mnemonic = try! Mnemonic(words: mnemonicBuilder.getWords())
					grid = .init(mnemonic: mnemonic)
				case let .recoverFactorSource(isOlympia):
					isEnteringCustomSeedPhrase = true
					hasPassphrase = isOlympia
					grid = .init(count: .twentyFour, wordCounts: isOlympia ? Bip39WordCount.allCases : [])
				}
			}
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Sendable, Hashable {
			case confirmButtonTapped
			case enterCustomSeedPhraseButtonTapped
			case passphraseChanged(String)
			case toggleModeButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Hashable {
			case grid(ImportMnemonicGrid.Action)
		}

		enum InternalAction: Sendable, Equatable {
			case factorAlreadyInUse(FactorSource)
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
			case .confirmButtonTapped:
				let isEnteringCustomSeedPhrase = state.isEnteringCustomSeedPhrase
				if isEnteringCustomSeedPhrase {
					state.$mnemonicBuilder.withLock { builder in
						if let builderWithMnemonic = try? builder.createMnemonicFromWords(words: state.grid.completedWords.map(\.word)) {
							builder = builderWithMnemonic
						}
					}
				}
				let factorSourceId = state.mnemonicBuilder.getFactorSourceId(kind: state.factorSourceKind)
				return .run { [kind = state.factorSourceKind, context = state.context] send in
					let existingFactorSource = try SargonOs.shared.factorSources().first(where: { $0.id == factorSourceId })
					if let existingFactorSource {
						if kind == .device {
							let newParamters = switch context {
							case .newFactorSource, .recoverFactorSource(false):
								FactorSourceCryptoParameters.babylon
							case .recoverFactorSource(true):
								FactorSourceCryptoParameters.olympia
							}

							try await SargonOs.shared.appendCryptoParametersToFactorSource(factorSourceId: factorSourceId, cryptoParameters: newParamters)
						}
						await send(.internal(.factorAlreadyInUse(existingFactorSource)))
					} else {
						await send(.delegate(.completed(withCustomSeedPhrase: isEnteringCustomSeedPhrase)))
					}
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case .enterCustomSeedPhraseButtonTapped:
				state.grid = .init(count: .twentyFour, wordCounts: state.factorSourceKind == .arculusCard ? [.twelve, .twentyFour] : [])
				state.isEnteringCustomSeedPhrase = true
				return .none

			case .toggleModeButtonTapped:
				state.advancedModeEnabled.toggle()
				return .none

			case let .passphraseChanged(passphrase):
				state.bip39Passphrase = passphrase
				return .none
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .factorAlreadyInUse(fs):
				state.destination = Destination.factorAlreadyInUseState(fs)
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

extension AddFactorSource.InputSeedPhrase.Destination {
	static func factorAlreadyInUseState(_ fs: FactorSource) -> State {
		.factorAlreadyInUseAlert(.init(
			title: {
				TextState("Factor Already In Use")
			},
			actions: {
				ButtonState(role: .cancel, action: .close) {
					TextState("Ok")
				}
			},
			message: {
				TextState(fs.name)
			}
		))
	}
}
