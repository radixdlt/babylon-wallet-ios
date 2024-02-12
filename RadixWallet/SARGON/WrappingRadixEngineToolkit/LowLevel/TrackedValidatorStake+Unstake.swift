import Foundation

// MARK: - TrackedValidatorUnstake
public enum TrackedValidatorUnstake: TrackedPoolInteractionStuff {}

// MARK: - TrackedValidatorStake
public enum TrackedValidatorStake: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolInteractionStuff
public protocol TrackedPoolInteractionStuff: DummySargon {}

extension TrackedPoolInteractionStuff {
	public var validatorAddress: ValidatorAddress {
		panic()
	}

	public var liquidStakeUnitAddress: ResourceAddress {
		panic()
	}

	public var liquidStakeUnitAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var xrdAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var poolAddress: ComponentAddress { panic() }
	public var poolUnitsResourceAddress: ResourceAddress { panic() }
	public var poolUnitsAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var resourcesInInteraction: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var contributedResources: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var redeemedResources: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}
}

// MARK: - TrackedPoolContribution
public enum TrackedPoolContribution: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolRedemption
public enum TrackedPoolRedemption: TrackedPoolInteractionStuff {}
