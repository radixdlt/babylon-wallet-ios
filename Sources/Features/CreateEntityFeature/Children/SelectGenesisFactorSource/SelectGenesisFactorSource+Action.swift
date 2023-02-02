import FeaturePrelude

// MARK: - SelectGenesisFactorSource.Action
public extension SelectGenesisFactorSource {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension SelectGenesisFactorSource.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - SelectGenesisFactorSource.Action.ViewAction
public extension SelectGenesisFactorSource.Action {
	enum ViewAction: Sendable, Equatable {
		case confirmOnDeviceFactorSource
	}
}

// MARK: - SelectGenesisFactorSource.Action.InternalAction
public extension SelectGenesisFactorSource.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - SelectGenesisFactorSource.Action.SystemAction
public extension SelectGenesisFactorSource.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - SelectGenesisFactorSource.Action.DelegateAction
public extension SelectGenesisFactorSource.Action {
	enum DelegateAction: Sendable, Equatable {
		case confirmedFactorSource(FactorSource, specifiedNameForNewEntityToCreate: String)
	}
}
