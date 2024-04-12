import Foundation
import Sargon

// MARK: - DiscrepancyOtherShouldNotContainCurrent
struct DiscrepancyOtherShouldNotContainCurrent: Swift.Error {}
extension Gateways {
	/// Swaps current and other gateways:
	///
	/// * Adds (old)`current` to `other` (throws error if it was already present)
	/// * Removes `newCurrent` from `other` (if present)
	/// * Sets `current = newCurrent`
	private mutating func changeCurrent(to newCurrent: Gateway) throws {
		guard newCurrent != current else {
			assert(other[id: current.id] == nil, "Discrepancy, `other` should not contain `current`.")
			return
		}
		let oldCurrent = self.current
		let (wasInserted, _) = other.append(oldCurrent)
		guard wasInserted else {
			throw DiscrepancyOtherShouldNotContainCurrent()
		}
		other.remove(id: newCurrent.id)
		current = newCurrent
	}

	public mutating func changeCurrentToMainnetIfNeeded() {
		if current == .mainnet { return }
		try? changeCurrent(to: .mainnet)
	}

	/// Adds `newOther` to `other` (if indeed new).
	private mutating func add(_ newOther: Gateway) {
		other.append(newOther)
	}

	private mutating func remove(_ gateway: Gateway) {
		other.remove(gateway)
	}
}
