import Foundation

// MARK: - TrackedValidatorUnstake
public enum TrackedValidatorUnstake: TrackedPoolInteractionStuff {}

// MARK: - TrackedValidatorStake
public enum TrackedValidatorStake: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolInteractionStuff
public protocol TrackedPoolInteractionStuff: DummySargon {}

extension TrackedPoolInteractionStuff {
	public var validatorAddress: ValidatorAddress {
		sargon()
	}

	public var liquidStakeUnitAddress: ResourceAddress {
		sargon()
	}

	public var liquidStakeUnitAmount: Decimal192 {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var xrdAmount: Decimal192 {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var poolAddress: PoolAddress { sargon() }
	public var poolUnitsResourceAddress: ResourceAddress { sargon() }
	public var poolUnitsAmount: Decimal192 {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var resourcesInInteraction: [String: Decimal192] {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var contributedResources: [String: Decimal192] {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var redeemedResources: [String: Decimal192] {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}
}

// MARK: - TrackedPoolContribution
public enum TrackedPoolContribution: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolRedemption
public enum TrackedPoolRedemption: TrackedPoolInteractionStuff {}
