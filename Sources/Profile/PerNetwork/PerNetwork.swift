import EngineToolkitModels
import Prelude

// MARK: - Profile.Networks
extension Profile {
	/// An ordered dictionary mapping from a `Network` to an `Profile.Network`, which is a
	/// collection of accounts, personas and connected dapps.
	public struct Networks:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpStringConvertible,
		ExpressibleByDictionaryLiteral
	{
		/// An ordered dictionary mapping from a `Network` to an `Profile.Network`, which is a
		/// collection of accounts, personas and connected dapps.
		public internal(set) var dictionary: OrderedDictionary<NetworkID, Profile.Network>

		public init(dictionary: OrderedDictionary<NetworkID, Profile.Network>) {
			self.dictionary = dictionary
		}

		public init(network: Profile.Network) {
			self.init(dictionary: [network.networkID: network])
		}
	}
}

extension Profile.Networks {
	public typealias Key = NetworkID

	public typealias Value = Profile.Network

	public init(dictionaryLiteral elements: (Key, Value)...) {
		self.init(dictionary: .init(uniqueKeysWithValues: elements))
	}

	public var count: Int {
		dictionary.count
	}

	public var keys: OrderedSet<NetworkID> {
		dictionary.keys
	}

	public var values: some Collection<Profile.Network> {
		dictionary.values
	}

	public func network(id needle: NetworkID) throws -> Profile.Network {
		guard let network = dictionary[needle] else {
			throw Error.unknownNetworkWithID(needle)
		}
		return network
	}

	public enum Error:
		Swift.Error,
		Sendable,
		Hashable,
		CustomStringConvertible,
		CustomDumpStringConvertible
	{
		case unknownNetworkWithID(NetworkID)
		case networkAlreadyExistsWithID(NetworkID)
	}

	public mutating func update(_ network: Profile.Network) throws {
		guard dictionary.contains(where: { $0.key == network.networkID }) else {
			throw Error.unknownNetworkWithID(network.networkID)
		}
		let updatedElement = dictionary.updateValue(network, forKey: network.networkID)
		assert(updatedElement != nil)
	}

	public mutating func add(_ network: Profile.Network) throws {
		guard !dictionary.contains(where: { $0.key == network.networkID }) else {
			throw Error.networkAlreadyExistsWithID(network.networkID)
		}
		let updatedElement = dictionary.updateValue(network, forKey: network.networkID)
		assert(updatedElement == nil)
	}
}

extension Profile.Networks.Error {
	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}

	public var _description: String {
		switch self {
		case let .unknownNetworkWithID(id): return "Profile.Networks.Error.unknownNetworkWithID(\(id))"
		case let .networkAlreadyExistsWithID(id): return "Profile.Networks.Error.networkAlreadyExistsWithID(\(id))"
		}
	}
}

extension Profile.Networks {
	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		let array = try singleValueContainer.decode([Profile.Network].self)
		self.init(dictionary: .init(uniqueKeysWithValues: array.map { element in
			(key: element.networkID, value: element)
		}))
	}

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		let networkArray = [Profile.Network](self.dictionary.values)
		try singleValueContainer.encode(networkArray)
	}
}

extension Profile.Networks {
	public var _description: String {
		String(describing: dictionary)
	}

	public var description: String {
		_description
	}

	public var customDumpDescription: String {
		_description
	}
}

// MARK: - OrderedSet + Sendable
extension OrderedSet: @unchecked Sendable {}

// MARK: - OrderedDictionary + Sendable
extension OrderedDictionary: @unchecked Sendable where Key: Sendable, Value: Sendable {}
