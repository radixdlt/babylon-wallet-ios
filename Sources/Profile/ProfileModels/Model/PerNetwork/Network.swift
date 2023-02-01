import EngineToolkitModels
import Prelude

// MARK: - Network
public struct Network:
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	public let name: Name
	public let id: NetworkID

	public init(name: Name, id: NetworkID) {
		self.name = name
		self.id = id
	}
}

public extension Network {
	typealias Name = Tagged<Self, String>

	static let nebunet = Self(
		name: "betanet",
		id: .nebunet
	)
	static let hammunet = Self(
		name: "hammunet",
		id: .hammunet
	)
	static let enkinet = Self(
		name: "enkinet",
		id: .enkinet
	)
	static let mardunet = Self(
		name: "mardunet",
		id: .mardunet
	)
}

private extension Network {
	static let lookupSet: Set<Network> = [
		.nebunet,
		.hammunet,
		.enkinet,
		.mardunet,
	]
}

public extension Network {
	static func lookupBy(name rawValue: Name.RawValue) throws -> Self {
		guard let network = lookupSet.first(where: { $0.name.rawValue == rawValue }) else {
			throw UnknownNetwork(description: "No network found with name: '\(rawValue)'")
		}
		return network
	}

	static func lookupBy(name: Name) throws -> Self {
		try lookupBy(name: name.rawValue)
	}

	static func lookupBy(id: NetworkID) throws -> Self {
		guard let network = lookupSet.first(where: { $0.id == id }) else {
			throw UnknownNetwork(description: "No network found with id: '\(id)'")
		}
		return network
	}
}

// MARK: - UnknownNetwork
struct UnknownNetwork: Swift.Error, CustomStringConvertible {
	let description: String
}

public extension Network {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"name": name,
				"id": id,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		name: \(name),
		id: \(id)
		"""
	}
}
