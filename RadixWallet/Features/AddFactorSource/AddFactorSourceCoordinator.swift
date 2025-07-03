import ComposableArchitecture
import Sargon

extension AddFactorSource {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			enum Mode {
				case preselectedKind(FactorSourceKind)
				case toSelectFromKinds([FactorSourceKind])
			}

			@Shared(.deviceMnemonicBuilder) var deviceMnemonicBuilder
			var kind: FactorSourceKind?

			var root: Root.State
			var path: StackState<Path.State>

			init(mode: Mode) {
				switch mode {
				case let .preselectedKind(factorSourceKind):
					self.kind = factorSourceKind
					self.root = .intro(.init(kind: factorSourceKind))
				case let .toSelectFromKinds(kinds):
					self.kind = nil
					self.root = .selectKind(.init(kinds: kinds))
				}
				self.path = .init()
			}
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro(AddFactorSource.Intro)
			case deviceSeedPhrase(AddFactorSource.DeviceSeedPhrase)
			case confirmSeedPhrase(AddFactorSource.ConfirmSeedPhrase)
			case nameFactorSource(AddFactorSource.NameFactorSource)
		}

		@Reducer
		struct Root {
			@CasePathable
			@ObservableState
			enum State: Hashable, Sendable {
				case selectKind(AddFactorSource.SelectKind.State)
				case intro(AddFactorSource.Intro.State)
			}

			@CasePathable
			enum Action: Equatable, Sendable {
				case selectKind(AddFactorSource.SelectKind.Action)
				case intro(AddFactorSource.Intro.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.selectKind, action: \.selectKind) {
					AddFactorSource.SelectKind()
				}

				Scope(state: \.intro, action: \.intro) {
					AddFactorSource.Intro()
				}
			}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case continueButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Root.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Root()
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
				case .none:
					return .none
				}

				return .none
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .root(.selectKind(.delegate(.completed(selectedKind)))):
				state.kind = selectedKind
				state.path.append(.intro(.init(kind: selectedKind)))
				return .none
			case .root(.intro(.delegate(.completed))), .path(.element(id: _, action: .intro(.delegate(.completed)))):
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
				case .none:
					return .none
				}

				return .none
			case let .path(.element(id: _, action: .deviceSeedPhrase(.delegate(.completed(withCustomSeedPhrase))))):
				guard let kind = state.kind else {
					return .none
				}

				if withCustomSeedPhrase {
					state.path.append(.nameFactorSource(.init(kind: kind)))
				} else {
					state.path.append(.confirmSeedPhrase(.init(factorSourceKind: kind)))
				}
				return .none
			case .path(.element(id: _, action: .confirmSeedPhrase(.delegate(.validated)))):
				guard let kind = state.kind else {
					return .none
				}

				state.path.append(.nameFactorSource(.init(kind: kind)))
				return .none
			case .path(.element(id: _, action: .nameFactorSource(.delegate(.saved)))):
				return .send(.delegate(.finished))
			default:
				return .none
			}
		}
	}
}
