import Foundation

// MARK: - TrackedPoolInteraction
public protocol TrackedPoolInteraction {
	var poolAddress: PoolAddress { get }
	var poolUnitsResourceAddress: ResourceAddress { get }
	var poolUnitsAmount: Decimal192 { get set }
	var resourcesInInteraction: [String: Decimal192] { get set }
	mutating func add(_ other: Self)
}

// MARK: - TrackedPoolContribution + TrackedPoolInteraction
extension TrackedPoolContribution: TrackedPoolInteraction {
	public var resourcesInInteraction: [String: Decimal192] {
		get { contributedResources }
		set { contributedResources = newValue }
	}
}

// MARK: - TrackedPoolRedemption + TrackedPoolInteraction
extension TrackedPoolRedemption: TrackedPoolInteraction {
	public var resourcesInInteraction: [String: Decimal192] {
		get { redeemedResources }
		set { redeemedResources = newValue }
	}
}

extension Collection where Element: TrackedPoolInteraction {
	public var aggregated: [Element] {
		var result: [Element] = []
		for poolInteraction in self {
			// Make sure no contribution is empty
			guard poolInteraction.poolUnitsAmount > 0 else { continue }
			if let i = result.firstIndex(where: { $0.poolAddress == poolInteraction.poolAddress }) {
				result[i].add(poolInteraction)
			} else {
				result.append(poolInteraction)
			}
		}
		return result
	}
}

extension TrackedPoolInteraction {
	public mutating func add(_ other: Self) {
		guard other.poolAddress == poolAddress, other.poolUnitsResourceAddress == poolUnitsResourceAddress else {
			assertionFailure("The pools should have the same address and pool unit")
			return
		}
		for (resource, amount) in other.resourcesInInteraction {
			guard let currentInteraction = resourcesInInteraction[resource] else {
				assertionFailure("The pools should have the same resources")
				return
			}
			resourcesInInteraction[resource] = currentInteraction + amount
		}
		poolUnitsAmount = poolUnitsAmount + other.poolUnitsAmount
	}
}
