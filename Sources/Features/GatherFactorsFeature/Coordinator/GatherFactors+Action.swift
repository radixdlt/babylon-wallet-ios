import FeaturePrelude

// MARK: - GatherFactors.Action
public extension GatherFactors {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
		case child(ChildAction)
	}
}

public extension GatherFactors.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - GatherFactors.Action.ChildAction
public extension GatherFactors.Action {
	enum ChildAction: Sendable, Equatable {
		case gatherFactor(
			GatherFactor<Purpose>.Action
		)
	}
}

// MARK: - GatherFactors.Action.ViewAction
public extension GatherFactors.Action {
	enum ViewAction: Sendable, Equatable {
		/// Next or Finish
		case proceed
	}
}

// MARK: - GatherFactors.Action.InternalAction
public extension GatherFactors.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - GatherFactors.Action.SystemAction
public extension GatherFactors.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - GatherFactors.Action.DelegateAction
public extension GatherFactors.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case finishedWithResult(Purpose.Produce)
	}
}
