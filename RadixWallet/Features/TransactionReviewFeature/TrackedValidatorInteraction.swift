import Foundation

// MARK: - TrackedValidatorInteraction
public protocol TrackedValidatorInteraction {
	var validatorAddress: ValidatorAddress { get }
	var liquidStakeUnitAddress: ResourceAddress { get }
	var liquidStakeUnitAmount: RETDecimal { get set }
	mutating func add(_ other: Self)
}

extension Collection where Element: TrackedValidatorInteraction {
	public var aggregated: [Element] {
		var result: [Element] = []
		for stake in self {
			// Make sure no contribution is empty
			guard stake.liquidStakeUnitAmount > 0 else { continue }
			if let i = result.firstIndex(where: { $0.validatorAddress == stake.validatorAddress }) {
				result[i].add(stake)
			} else {
				result.append(stake)
			}
		}
		return result
	}
}

// MARK: - TrackedValidatorUnstake + TrackedValidatorInteraction
extension TrackedValidatorUnstake: TrackedValidatorInteraction {
	public mutating func add(_ other: Self) {
		guard isCompatible(with: other) else { return }
		liquidStakeUnitAmount += other.liquidStakeUnitAmount
	}
}

// MARK: - TrackedValidatorStake + TrackedValidatorInteraction
extension TrackedValidatorStake: TrackedValidatorInteraction {
	public mutating func add(_ other: Self) {
		guard isCompatible(with: other) else { return }
		xrdAmount += other.xrdAmount
		liquidStakeUnitAmount += other.liquidStakeUnitAmount
	}
}

private extension TrackedValidatorInteraction {
	func isCompatible(with other: Self) -> Bool {
		guard other.validatorAddress == validatorAddress, other.liquidStakeUnitAddress == liquidStakeUnitAddress else {
			assertionFailure("The stakes should have the same validator and LSU")
			return false
		}

		return true
	}
}
