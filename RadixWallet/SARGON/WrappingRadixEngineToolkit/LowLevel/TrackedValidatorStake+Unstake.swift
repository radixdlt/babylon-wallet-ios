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

	public var liquidStakeUnitAmount: RETDecimal {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var xrdAmount: RETDecimal {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var poolAddress: ComponentAddress { sargon() }
	public var poolUnitsResourceAddress: ResourceAddress { sargon() }
	public var poolUnitsAmount: RETDecimal {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var resourcesInInteraction: [String: RETDecimal] {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var contributedResources: [String: RETDecimal] {
		get {
			sargon()
		}
		set {
			sargon()
		}
	}

	public var redeemedResources: [String: RETDecimal] {
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
