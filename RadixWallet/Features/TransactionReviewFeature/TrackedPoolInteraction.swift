import Foundation

//// MARK: - TrackedPoolInteraction
// public protocol TrackedPoolInteraction {
//	var poolAddress: EngineToolkit.Address { get }
//	var poolUnitsResourceAddress: EngineToolkit.Address { get }
//	var poolUnitsAmount: RETDecimal { get set }
//	var resourcesInInteraction: [String: RETDecimal] { get set }
// }
//
//// MARK: - TrackedPoolContribution + TrackedPoolInteraction
// extension TrackedPoolContribution: TrackedPoolInteraction {
//	public var resourcesInInteraction: [String: RETDecimal] {
//		get { contributedResources }
//		set { contributedResources = newValue }
//	}
// }
//
//// MARK: - TrackedPoolRedemption + TrackedPoolInteraction
// extension TrackedPoolRedemption: TrackedPoolInteraction {
//	public var resourcesInInteraction: [String: RETDecimal] {
//		get { redeemedResources }
//		set { redeemedResources = newValue }
//	}
// }
//
// extension Collection where Element: TrackedPoolInteraction {
//	public var aggregated: [Element] {
//		var result: [Element] = []
//		for poolInteraction in self {
//			// Make sure no contribution is empty
//			guard poolInteraction.poolUnitsAmount > 0 else { continue }
//			if let i = result.firstIndex(where: { $0.poolAddress == poolInteraction.poolAddress }) {
//				result[i].add(poolInteraction)
//			} else {
//				result.append(poolInteraction)
//			}
//		}
//		return result
//	}
// }
//
// private extension TrackedPoolInteraction {
//	mutating func add(_ other: Self) {
//		guard other.poolAddress == poolAddress, other.poolUnitsResourceAddress == poolUnitsResourceAddress else { return }
//		for (resource, amount) in other.resourcesInInteraction {
//			guard let currentInteraction = resourcesInInteraction[resource] else {
//				assertionFailure("The pools should have the same resources")
//				return
//			}
//			resourcesInInteraction[resource] = currentInteraction + amount
//		}
//		poolUnitsAmount = poolUnitsAmount + other.poolUnitsAmount
//	}
// }
