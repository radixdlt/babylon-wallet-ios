import EngineKit
import Prelude

// MARK: - Gateways
public struct Gateways:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// Current
	public private(set) var current: Radix.Gateway

	/// Other, does not contain current, use `all` if you want to get all.
	public private(set) var other: IdentifiedArrayOf<Radix.Gateway>

	public init(
		current: Radix.Gateway
	) {
		self.current = current
		self.other = .init()
	}

	public static let preset = try! Self(current: .mainnet, other: [.stokenet])

	public init(
		current: Radix.Gateway,
		other: IdentifiedArrayOf<Radix.Gateway>
	) throws {
		guard other[id: current.id] == nil else {
			throw DiscrepancyOtherShouldNotContainCurrent()
		}
		self.current = current
		self.other = other
	}
}

extension Gateways {
	public typealias Elements = NonEmpty<IdentifiedArrayOf<Radix.Gateway>>

	/// All gateways
	public var all: Elements {
		var elements = IdentifiedArrayOf<Radix.Gateway>(uniqueElements: [current])
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
	fileprivate mutating func changeCurrent(to newCurrent: Radix.Gateway) throws {
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
	fileprivate mutating func add(_ newOther: Radix.Gateway) {
		other.append(newOther)
	}

	fileprivate mutating func remove(_ gateway: Radix.Gateway) {
		other.remove(gateway)
	}
}

extension Profile {
	/// Requires the presence of an `Profile.Network` in `networks` for
	/// `newGateway.network.id`, otherwise an error is thrown.
	public mutating func changeGateway(to newGateway: Radix.Gateway) throws {
		let newNetworkID = newGateway.network.id
		// Ensure we have accounts on network, else do not change
		_ = try network(id: newNetworkID)
		try appPreferences.gateways.changeCurrent(to: newGateway)
	}

	public mutating func addNewGateway(_ newGateway: Radix.Gateway) throws {
		appPreferences.gateways.add(newGateway)
	}

	public mutating func removeGateway(_ gateway: Radix.Gateway) throws {
		appPreferences.gateways.remove(gateway)
	}
}

extension Gateways {
	private enum CodingKeys: String, CodingKey {
		case current
		case all = "saved"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let urlOfCurrent = try container.decode(URL.self, forKey: .current)
		let all = try container.decode(IdentifiedArrayOf<Radix.Gateway>.self, forKey: .all)
		guard let current = all.first(where: { $0.id == urlOfCurrent }) else {
			struct DiscrepancyCurrentNotFoundAmongstSavedGateways: Swift.Error {}
			throw DiscrepancyCurrentNotFoundAmongstSavedGateways()
		}
		var other = all
		other.remove(id: current.id)
		try self.init(current: current, other: other)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(current.url, forKey: .current)
		try container.encode(all, forKey: .all)
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
