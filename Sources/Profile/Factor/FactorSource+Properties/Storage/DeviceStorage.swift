import EngineToolkitModels
import Prelude

// MARK: - OnNetwork.NextDerivationIndicies
extension OnNetwork {
	public struct NextDerivationIndicies: Sendable, Hashable, Codable, Identifiable {
		public typealias Index = Int

		public typealias ID = NetworkID
		public let networkID: NetworkID
		public var id: ID { networkID }

		public var forAccount: Index
		public var forIdentity: Index

		public init(
			networkID: NetworkID,
			forAccount: UInt,
			forIdentity: UInt
		) {
			self.networkID = networkID
			self.forAccount = Index(forAccount)
			self.forIdentity = Index(forIdentity)
		}
	}
}

// MARK: - NextDerivationIndiciesPerNetwork
/// An ordered dictionary mapping from a `Network` to a `NextDerivationIndicies`, which is a
/// holds derivation indices for entities.
public struct NextDerivationIndiciesPerNetwork:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public internal(set) var perNetwork: IdentifiedArrayOf<OnNetwork.NextDerivationIndicies>

	public init(perNetwork: IdentifiedArrayOf<OnNetwork.NextDerivationIndicies>) {
		self.perNetwork = perNetwork
	}

	public init(nextDerivationIndicies: OnNetwork.NextDerivationIndicies) {
		self.init(perNetwork: .init(uncheckedUniqueElements: [nextDerivationIndicies]))
	}

	public init() {
		self.init(perNetwork: .init())
	}
}

extension NextDerivationIndiciesPerNetwork {
	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		try self.init(perNetwork: singleValueContainer.decode(IdentifiedArrayOf<OnNetwork.NextDerivationIndicies>.self))
	}

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(self.perNetwork)
	}
}

extension NextDerivationIndiciesPerNetwork {
	public var _description: String {
		String(describing: perNetwork)
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
	public var nextDerivationIndiciesPerNetwork: NextDerivationIndiciesPerNetwork
	public init(nextDerivationIndiciesPerNetwork: NextDerivationIndiciesPerNetwork = .init()) {
		self.nextDerivationIndiciesPerNetwork = nextDerivationIndiciesPerNetwork
	}
}

extension OnNetwork.NextDerivationIndicies {
	public func nextForEntity(kind entityKind: EntityKind) -> Index {
		switch entityKind {
		case .identity: return forIdentity
		case .account: return forAccount
		}
	}
}

// MARK: - UnknownNetworkForDerivationIndicies
struct UnknownNetworkForDerivationIndicies: Swift.Error {}
extension NextDerivationIndiciesPerNetwork {
	public func nextForEntity(
		kind entityKind: EntityKind,
		networkID: Network.ID
	) -> OnNetwork.NextDerivationIndicies.Index {
		guard let onNetwork = self.perNetwork[id: networkID] else {
			return 0
		}
		return onNetwork.nextForEntity(kind: entityKind)
	}
}

extension DeviceStorage {
	public func nextForEntity(
		kind entityKind: EntityKind,
		networkID: Network.ID
	) -> OnNetwork.NextDerivationIndicies.Index {
		self.nextDerivationIndiciesPerNetwork.nextForEntity(kind: entityKind, networkID: networkID)
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
		nextDerivationIndiciesPerNetwork.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
	}
}

extension NextDerivationIndiciesPerNetwork {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) {
		guard var onNetwork = self.perNetwork[id: networkID] else {
			// first on network
			self.perNetwork[id: networkID] = .init(
				networkID: networkID,
				forAccount: entityKind == .account ? 1 : 0,
				forIdentity: entityKind == .identity ? 1 : 0
			)
			return
		}
		onNetwork.increaseNextDerivationIndex(for: entityKind)
		self.perNetwork[id: networkID] = onNetwork
	}
}

extension OnNetwork.NextDerivationIndicies {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
		switch entityKind {
		case .account: self.forAccount += 1
		case .identity: self.forIdentity += 1
		}
	}
}
