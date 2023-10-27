import Foundation
import IdentifiedCollections

// MARK: - DefaultValueProvider
/// An utility property wrapper allowing to specify a default value if the decoded value is missing or nil

/// Provides the Type of the decoded value, also its default value
public protocol DefaultValueProvider {
	associatedtype Value: Codable
	static var defaultValue: Value { get }
}

// MARK: - DefaultCodable
public enum DefaultCodable {
	/// The property wrapper itself.
	/// Need to make use of the tagging with the protocol, since the value provided in `init` will not be
	/// accessible when initializing with the decoder.
	@propertyWrapper
	public struct Wrapper<Provider: DefaultValueProvider>: Codable {
		public typealias Value = Provider.Value
		public var wrappedValue = Provider.defaultValue

		public init(wrappedValue: Provider.Value = Provider.defaultValue) {
			self.wrappedValue = wrappedValue
		}
	}
}

// MARK: - Default Value Providers
extension DefaultCodable {
	public typealias AnyCollection = Codable & EmptyInitializable
	public typealias EmptyCollection<Collection: AnyCollection> = Wrapper<Providers.EmptyCollection<Collection>>

	public enum Providers {
		public enum EmptyCollection<Collection: Codable & EmptyInitializable>: DefaultValueProvider {
			public static var defaultValue: Collection { .init() }
		}
	}
}

// MARK: - Set + EmptyInitializable
extension Set: EmptyInitializable {}

// MARK: - IdentifiedArray + EmptyInitializable
extension IdentifiedArray: EmptyInitializable where Element: Identifiable, ID == Element.ID {
	public init() {
		self.init(id: \.id)
	}
}

// MARK: - Decoding
extension DefaultCodable.Wrapper {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		wrappedValue = try container.decode(Value.self)
	}
}

extension KeyedDecodingContainer {
	public func decode<T>(
		_ type: DefaultCodable.Wrapper<T>.Type,
		forKey key: Key
	) throws -> DefaultCodable.Wrapper<T> {
		try decodeIfPresent(type, forKey: key) ?? .init()
	}
}

// MARK: - Encoding
extension KeyedEncodingContainer {
	public mutating func encode(_ value: DefaultCodable.Wrapper<some Any>, forKey key: Key) throws {
		try encode(value.wrappedValue, forKey: key)
	}
}

// MARK: - DefaultCodable.Wrapper + Equatable
extension DefaultCodable.Wrapper: Equatable where Provider.Value: Equatable {}

// MARK: - DefaultCodable.Wrapper + Hashable
extension DefaultCodable.Wrapper: Hashable where Provider.Value: Hashable {}

// MARK: - DefaultCodable.Wrapper + Sendable
extension DefaultCodable.Wrapper: Sendable where Provider.Value: Sendable {}
