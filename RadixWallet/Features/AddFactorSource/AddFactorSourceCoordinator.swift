import ComposableArchitecture
import Sargon

extension AddFactorSource {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind

			var root: Path.State = .intro
			var path: StackState<Path.State> = .init()
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro
			case deviceSeedPhrase(AddFactorSource.DeviceSeedPhrase)
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

		@Dependency(\.errorQueue) var errorQueue

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
					state.path.append(.deviceSeedPhrase(.init()))
				case .ledgerHqHardwareWallet, .offDeviceMnemonic, .arculusCard, .password:
					break
				}

				return .none
			}
		}

		//        func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		//            switch childAction {
		//            case .root(.intro(.delegate(.finished))):
		//                state.path.append(...)
		//                return .none
		//            case let .path(.element(id: _, action: .choosePersonas(.delegate(.finished(personas))))):
		//                state.selectedPersonas = personas
		//                state.path.append(.completion)
		//                return .none
		//            default:
		//                return .none
		//            }
		//        }
	}
}
