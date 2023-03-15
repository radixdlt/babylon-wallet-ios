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
	public let displayDescription: String

	public init(
		name: Name,
		id: NetworkID,
		displayDescription: String
	) {
		self.name = name
		self.id = id
		self.displayDescription = displayDescription
	}
}

extension Network {
	public typealias Name = Tagged<Self, String>

	public static let nebunet = Self(
		name: "nebunet",
		id: .nebunet,
		displayDescription: "Radix Public Network"
	)
	public static let hammunet = Self(
		name: "hammunet",
		id: .hammunet,
		displayDescription: "Hammunet (Test Network)"
	)
	public static let enkinet = Self(
		name: "enkinet",
		id: .enkinet,
		displayDescription: "Enkinet (Test Network)"
	)
	public static let mardunet = Self(
		name: "mardunet",
		id: .mardunet,
		displayDescription: "Mardunet (Test Network)"
	)
}

extension Network {
	fileprivate static let lookupSet: Set<Network> = [
		.nebunet,
		.hammunet,
		.enkinet,
		.mardunet,
	]
}

extension Network {
	public static func lookupBy(name rawValue: Name.RawValue) throws -> Self {
		guard let network = lookupSet.first(where: { $0.name.rawValue == rawValue }) else {
			throw UnknownNetwork(description: "No network found with name: '\(rawValue)'")
		}
		return network
	}

	public static func lookupBy(name: Name) throws -> Self {
		try lookupBy(name: name.rawValue)
	}

	public static func lookupBy(id: NetworkID) throws -> Self {
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

extension Network {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"name": name,
				"id": id,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		name: \(name),
		id: \(id)
		"""
	}
}
