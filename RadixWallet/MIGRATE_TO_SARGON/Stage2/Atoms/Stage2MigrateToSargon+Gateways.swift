import Foundation
import Sargon

// MARK: - DiscrepancyOtherShouldNotContainCurrent
struct DiscrepancyOtherShouldNotContainCurrent: Swift.Error {}
extension SavedGateways {
	mutating func changeCurrentToMainnetIfNeeded() {
		if current == .mainnet { return }
		try? changeCurrent(to: .mainnet)
	}

	/// Adds `newOther` to `other` (if indeed new).
	mutating func add(_ newOther: Gateway) {
		other.append(newOther)
	}

	mutating func remove(_ gateway: Gateway) {
		var identifiedOther = other.asIdentified()
		identifiedOther.remove(gateway)
		other = identifiedOther.elements
	}

	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"current": current,
				"other": other,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		current: \(current),
		other: \(other)
		"""
	}
}
