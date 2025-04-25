import ComposableArchitecture
import Sargon

extension AddFactorSource {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			@Shared(.deviceMnemonicBuilder) var deviceMnemonicBuilder
			let kind: FactorSourceKind

			var root: Path.State = .intro
			var path: StackState<Path.State> = .init()
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro
			case deviceSeedPhrase(AddFactorSource.DeviceSeedPhrase)
			case confirmSeedPhrase(AddFactorSource.ConfirmSeedPhrase)
			case nameFactorSource(AddFactorSource.NameFactorSource)
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case continueButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Path.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Path.intro
			}
			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .continueButtonTapped:
				switch state.kind {
				case .device:
					state.$deviceMnemonicBuilder.withLock { builder in
						builder = builder.generateNewMnemonic()
					}
					if let mnemonic = try? Mnemonic(words: state.deviceMnemonicBuilder.getWords()) {
						state.path.append(.deviceSeedPhrase(.init(mnemonic: mnemonic)))
					}
				case .ledgerHqHardwareWallet, .offDeviceMnemonic, .arculusCard, .password:
					break
				}

				return .none
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .path(.element(id: _, action: .deviceSeedPhrase(.delegate(.completed(withCustomSeedPhrase))))):
				if withCustomSeedPhrase {
					state.path.append(.nameFactorSource(.init(kind: state.kind)))
				} else {
					state.path.append(.confirmSeedPhrase(.init(factorSourceKind: state.kind)))
				}
				return .none
			case .path(.element(id: _, action: .confirmSeedPhrase(.delegate(.validated)))):
				state.path.append(.nameFactorSource(.init(kind: state.kind)))
				return .none
			case .path(.element(id: _, action: .nameFactorSource(.delegate(.saved)))):
				return .send(.delegate(.finished))
			default:
				return .none
			}
		}
	}
}
