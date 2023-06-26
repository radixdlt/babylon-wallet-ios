import FeaturePrelude

// MARK: - SelectFactorKindThenFactor
public struct SelectFactorKindThenFactor: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var factorSourceOfKind: FactorSourcesOfKindList<FactorSource>.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case selected(FactorSourceKind)
	}

	public enum ChildAction: Sendable, Equatable {
		case factorSourceOfKind(PresentationAction<FactorSourcesOfKindList<FactorSource>.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FactorSource)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$factorSourceOfKind, action: /Action.child .. ChildAction.factorSourceOfKind) {
				FactorSourcesOfKindList<FactorSource>()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selected(kind):
			state.factorSourceOfKind = .init(kind: kind, mode: .selection)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .factorSourceOfKind(.presented(.delegate(.choseFactorSource(factorSource)))):
			return .send(.delegate(.selected(factorSource)))
		default:
			return .none
		}
	}
}
