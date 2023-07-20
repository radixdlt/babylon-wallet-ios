import FeaturePrelude

public struct EditPersonaEntry<ContentReducer>: FeatureReducer where ContentReducer: FeatureReducer & EmptyInitializable {
	public struct State: Sendable, Hashable {
		let name: String
		let isRequestedByDapp: Bool

		var content: ContentReducer.State
	}

	public enum ChildAction: Sendable, Equatable {
		case content(ContentReducer.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case deleteButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case delete
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .deleteButtonTapped:
			return .send(.delegate(.delete))
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)

		Scope(
			state: \.content,
			action: /Action.child .. ChildAction.content,
			child: ContentReducer.init
		)
	}
}
