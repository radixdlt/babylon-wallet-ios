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

		public init(onNetwork: Profile.Network) {
			self.init(dictionary: [onNetwork.networkID: onNetwork])
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

	public func onNetwork(id needle: NetworkID) throws -> Profile.Network {
		guard let onNetwork = dictionary[needle] else {
			throw Error.unknownNetworkWithID(needle)
		}
		return onNetwork
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

	public mutating func update(_ onNetwork: Profile.Network) throws {
		guard dictionary.contains(where: { $0.key == onNetwork.networkID }) else {
			throw Error.unknownNetworkWithID(onNetwork.networkID)
		}
		let updatedElement = dictionary.updateValue(onNetwork, forKey: onNetwork.networkID)
		assert(updatedElement != nil)
	}

	public mutating func add(_ onNetwork: Profile.Network) throws {
		guard !dictionary.contains(where: { $0.key == onNetwork.networkID }) else {
			throw Error.networkAlreadyExistsWithID(onNetwork.networkID)
		}
		let updatedElement = dictionary.updateValue(onNetwork, forKey: onNetwork.networkID)
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
		let onNetworkArray = [Profile.Network](self.dictionary.values)
		try singleValueContainer.encode(onNetworkArray)
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
