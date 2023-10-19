import EngineToolkit

// MARK: - Radix
/// Just a namespace for Radix entities, e.g. `Radix.Network`
public enum Radix {}

// MARK: Radix.Network
extension Radix {
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
}

extension Radix.Network {
	public typealias Name = Tagged<Self, String>

	public static let mainnet = Self(
		name: "mainnet",
		id: .mainnet,
		displayDescription: "Mainnet"
	)

	public static let stokenet = Self(
		name: "stokenet",
		id: .stokenet,
		displayDescription: "Stokenet"
	)

	public static let nebunet = Self(
		name: "nebunet",
		id: .nebunet,
		displayDescription: "Betanet"
	)
	public static let kisharnet = Self(
		name: "kisharnet",
		id: .kisharnet,
		displayDescription: "RCnet"
	)

	public static let ansharnet = Self(
		name: "ansharnet",
		id: .ansharnet,
		displayDescription: "RCnet-V2 test network"
	)

	public static let zabanet = Self(
		name: "zabanet",
		id: .zabanet,
		displayDescription: "RCnet-V3 test network"
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

	public static let simulator = Self(
		name: "simulator",
		id: .simulator,
		displayDescription: "Simulator (Test Network)"
	)
}

extension Radix.Network {
	fileprivate static let lookupSet: Set<Self> = [
		.mainnet,
		.stokenet,
		.nebunet,
		.kisharnet,
		.ansharnet,
		.zabanet,
		.hammunet,
		.enkinet,
		.mardunet,
	]
}

extension Radix.Network {
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

extension Radix.Network {
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
