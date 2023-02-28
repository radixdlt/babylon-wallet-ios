import Prelude

// MARK: - Gateways
public struct Gateways:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	public private(set) var current: Gateway
	public private(set) var other: IdentifiedArrayOf<Gateway>

	public init(
		current: Gateway
	) {
		self.current = current
		self.other = .init()
	}

	public init(
		current: Gateway,
		other: IdentifiedArrayOf<Gateway>
	) throws {
		guard other[id: current.id] == nil else {
			throw DiscrepancyOtherShouldNotContainCurrent()
		}
		self.current = current
		self.other = other
	}
}

extension Gateways {
	public typealias Elements = NonEmpty<IdentifiedArrayOf<Gateway>>
	public var gateways: Elements {
		var elements = IdentifiedArrayOf<Gateway>(uniqueElements: [current])
		elements.append(contentsOf: other)
		return .init(rawValue: elements)!
	}
}

// MARK: - DiscrepancyOtherShouldNotContainCurrent
struct DiscrepancyOtherShouldNotContainCurrent: Swift.Error {}
extension Gateways {
	/// Swaps current and other gateways:
	///
	/// * Adds (old)`current` to `other` (throws error if it was already present)
	/// * Removes `newCurrent` from `other` (if present)
	/// * Sets `current = newCurrent`
	public mutating func changeCurrent(to newCurrent: Gateway) throws {
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

	/// Adds `newOther` to `other` (if indeed new).
	public mutating func add(_ newOther: Gateway, alsoSwitchTo: Bool = false) {
		other.append(newOther)
	}
}

extension Gateways {
	private enum CodingKeys: String, CodingKey {
		case current
		case other = "saved"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let urlOfCurrent = try container.decode(URL.self, forKey: .current)
		let gateways = try container.decode(IdentifiedArrayOf<Gateway>.self, forKey: .other)
		guard let current = gateways.first(where: { $0.id == urlOfCurrent }) else {
			struct DiscrepancyCurrentNotFoundAmongstSavedGateways: Swift.Error {}
			throw DiscrepancyCurrentNotFoundAmongstSavedGateways()
		}
		var other = gateways
		other.remove(id: current.id)
		try self.init(current: current, other: other)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(current.url, forKey: .current)
		try container.encode(other, forKey: .other)
	}
}

extension Gateways {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"current": current,
				"other": other,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		current: \(current),
		other: \(other)
		"""
	}
}
