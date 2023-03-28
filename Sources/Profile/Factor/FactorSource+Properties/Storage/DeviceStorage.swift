import EngineToolkitModels
import Prelude

// MARK: - Profile.Network.NextDerivationIndices
extension Profile.Network {
	public struct NextDerivationIndices: Sendable, Hashable, Codable, Identifiable {
		public typealias Index = UInt32

		public typealias ID = NetworkID
		public let networkID: NetworkID
		public var id: ID { networkID }

		public var forAccount: Index
		public var forIdentity: Index

		public init(
			networkID: NetworkID,
			forAccount: Index,
			forIdentity: Index
		) {
			self.networkID = networkID
			self.forAccount = forAccount
			self.forIdentity = forIdentity
		}
	}
}

// MARK: - NextDerivationIndicesPerNetwork
/// An ordered dictionary mapping from a `Network` to a `NextDerivationIndices`, which is a
/// holds derivation indices for entities.
public struct NextDerivationIndicesPerNetwork:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public internal(set) var networks: IdentifiedArrayOf<Profile.Network.NextDerivationIndices>

	public init(networks: IdentifiedArrayOf<Profile.Network.NextDerivationIndices>) {
		self.networks = networks
	}

	public init(nextDerivationIndices: Profile.Network.NextDerivationIndices) {
		self.init(networks: .init(uncheckedUniqueElements: [nextDerivationIndices]))
	}

	public init() {
		self.init(networks: .init())
	}
}

extension NextDerivationIndicesPerNetwork {
	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		try self.init(networks: singleValueContainer.decode(IdentifiedArrayOf<Profile.Network.NextDerivationIndices>.self))
	}

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(self.networks)
	}
}

extension NextDerivationIndicesPerNetwork {
	public var _description: String {
		String(describing: networks)
	}

	public var description: String {
		_description
	}

	public var customDumpDescription: String {
		_description
	}
}

// MARK: - DeviceStorage
public struct DeviceStorage: Sendable, Hashable, Codable {
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork
	public init(nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork = .init()) {
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
	}
}

extension Profile.Network.NextDerivationIndices {
	public func nextForEntity(kind entityKind: EntityKind) -> Index {
		switch entityKind {
		case .identity: return forIdentity
		case .account: return forAccount
		}
	}
}

// MARK: - UnknownNetworkForDerivationIndices
struct UnknownNetworkForDerivationIndices: Swift.Error {}
extension NextDerivationIndicesPerNetwork {
	public func nextForEntity(
		kind entityKind: EntityKind,
		networkID: Radix.Network.ID
	) -> Profile.Network.NextDerivationIndices.Index {
		guard let network = self.networks[id: networkID] else {
			return 0
		}
		return network.nextForEntity(kind: entityKind)
	}
}

extension DeviceStorage {
	public func nextForEntity(
		kind entityKind: EntityKind,
		networkID: Radix.Network.ID
	) -> Profile.Network.NextDerivationIndices.Index {
		self.nextDerivationIndicesPerNetwork.nextForEntity(kind: entityKind, networkID: networkID)
	}
}

extension FactorSource {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) throws {
		guard storage != nil else {
			throw Discrepancy()
		}
		try storage!.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
	}
}

extension FactorSource.Storage {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) throws {
		switch self {
		case .forSecurityQuestions: throw Discrepancy()
		case var .forDevice(deviceStorage):
			deviceStorage.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
			self = .forDevice(deviceStorage)
		}
	}
}

extension DeviceStorage {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) {
		nextDerivationIndicesPerNetwork.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
	}
}

extension NextDerivationIndicesPerNetwork {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) {
		guard var network = self.networks[id: networkID] else {
			// first on network
			self.networks[id: networkID] = .init(
				networkID: networkID,
				forAccount: entityKind == .account ? 1 : 0,
				forIdentity: entityKind == .identity ? 1 : 0
			)
			return
		}
		network.increaseNextDerivationIndex(for: entityKind)
		self.networks[id: networkID] = network
	}

	public mutating func setNextDerivationIndex(
		for entityKind: EntityKind,
		to index: Profile.Network.NextDerivationIndices.Index,
		networkID: NetworkID
	) {
		guard var network = self.networks[id: networkID] else {
			// first on network
			self.networks[id: networkID] = .init(
				networkID: networkID,
				forAccount: entityKind == .account ? index : 0,
				forIdentity: entityKind == .identity ? index : 0
			)
			return
		}
		network.setNextDerivationIndex(for: entityKind, to: index)
		self.networks[id: networkID] = network
	}
}

extension Profile.Network.NextDerivationIndices {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
		switch entityKind {
		case .account: self.forAccount += 1
		case .identity: self.forIdentity += 1
		}
	}

	public mutating func setNextDerivationIndex(for entityKind: EntityKind, to index: Index) {
		switch entityKind {
		case .account: self.forAccount = index
		case .identity: self.forIdentity = index
		}
	}
}
