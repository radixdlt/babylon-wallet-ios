import Cryptography
import FeaturePrelude

// MARK: - SelectGenesisFactorSource.Action
extension SelectGenesisFactorSource {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension SelectGenesisFactorSource.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - SelectGenesisFactorSource.Action.ViewAction
extension SelectGenesisFactorSource.Action {
	public enum ViewAction: Sendable, Equatable {
		case confirmOnDeviceFactorSource
		case selectedCurve(Slip10Curve)
	}
}

// MARK: - SelectGenesisFactorSource.Action.InternalAction
extension SelectGenesisFactorSource.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - SelectGenesisFactorSource.Action.SystemAction
extension SelectGenesisFactorSource.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - SelectGenesisFactorSource.Action.DelegateAction
extension SelectGenesisFactorSource.Action {
	public enum DelegateAction: Sendable, Equatable {
		case confirmedFactorSource(FactorSource, specifiedNameForNewEntityToCreate: NonEmpty<String>, curve: Slip10Curve)
	}
}
