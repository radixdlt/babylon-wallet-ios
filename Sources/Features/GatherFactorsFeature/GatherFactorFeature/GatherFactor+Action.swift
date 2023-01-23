import FeaturePrelude

// MARK: - GatherFactor.Action
public extension GatherFactor {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension GatherFactor.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - GatherFactor.Action.ViewAction
public extension GatherFactor.Action {
	enum ViewAction: Sendable, Equatable {
		case mockResultButtonTapped
	}
}

// MARK: - GatherFactor.Action.InternalAction
public extension GatherFactor.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - GatherFactor.Action.SystemAction
public extension GatherFactor.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - GatherFactor.Action.DelegateAction
public extension GatherFactor.Action {
	enum DelegateAction: Sendable, Equatable {
		case finishedWithResult(id: GatherFactor.State.ID, GatherFactorResult)
	}
}
