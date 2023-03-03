import EngineToolkitModels
import Prelude

// MARK: - PerNetwork
/// An ordered dictionary mapping from a `Network` to an `OnNetwork`, which is a
/// collection of accounts, personas and connected dapps.
public struct PerNetwork:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible,
	ExpressibleByDictionaryLiteral
{
	/// An ordered dictionary mapping from a `Network` to an `OnNetwork`, which is a
	/// collection of accounts, personas and connected dapps.
	public internal(set) var dictionary: OrderedDictionary<NetworkID, OnNetwork>

	public init(dictionary: OrderedDictionary<NetworkID, OnNetwork>) {
		self.dictionary = dictionary
	}

	public init(onNetwork: OnNetwork) {
		self.init(dictionary: [onNetwork.networkID: onNetwork])
	}
}

extension PerNetwork {
	public typealias Key = NetworkID

	public typealias Value = OnNetwork

	public init(dictionaryLiteral elements: (Key, Value)...) {
		self.init(dictionary: .init(uniqueKeysWithValues: elements))
	}

	public var count: Int {
		dictionary.count
	}

	public var keys: OrderedSet<NetworkID> {
		dictionary.keys
	}

	public func onNetwork(id needle: NetworkID) throws -> OnNetwork {
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

	public mutating func update(_ onNetwork: OnNetwork) throws {
		guard dictionary.contains(where: { $0.key == onNetwork.networkID }) else {
			throw Error.unknownNetworkWithID(onNetwork.networkID)
		}
		let updatedElement = dictionary.updateValue(onNetwork, forKey: onNetwork.networkID)
		assert(updatedElement != nil)
	}

	public mutating func add(_ onNetwork: OnNetwork) throws {
		guard !dictionary.contains(where: { $0.key == onNetwork.networkID }) else {
			throw Error.networkAlreadyExistsWithID(onNetwork.networkID)
		}
		let updatedElement = dictionary.updateValue(onNetwork, forKey: onNetwork.networkID)
		assert(updatedElement == nil)
	}
}

extension PerNetwork.Error {
	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}

	public var _description: String {
		switch self {
		case let .unknownNetworkWithID(id): return "PerNetwork.Error.unknownNetworkWithID(\(id))"
		case let .networkAlreadyExistsWithID(id): return "PerNetwork.Error.networkAlreadyExistsWithID(\(id))"
		}
	}
}

extension PerNetwork {
	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		let array = try singleValueContainer.decode([OnNetwork].self)
		self.init(dictionary: .init(uniqueKeysWithValues: array.map { element in
			(key: element.networkID, value: element)
		}))
	}

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		let onNetworkArray = [OnNetwork](self.dictionary.values)
		try singleValueContainer.encode(onNetworkArray)
	}
}

extension PerNetwork {
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
