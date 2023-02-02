import FeaturePrelude

// MARK: - NewProfile.Action
public extension NewProfile {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension NewProfile.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - NewProfile.Action.ViewAction
public extension NewProfile.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - NewProfile.Action.InternalAction
public extension NewProfile.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewProfile.Action.SystemAction
public extension NewProfile.Action {
	enum SystemAction: Sendable, Equatable {
		case createProfileResult(TaskResult<FactorSource>)
	}
}

// MARK: - NewProfile.Action.DelegateAction
public extension NewProfile.Action {
	enum DelegateAction: Sendable, Equatable {
		case criticalFailureCouldNotCreateProfile
		case createdProfile(factorSource: FactorSource)
	}
}
