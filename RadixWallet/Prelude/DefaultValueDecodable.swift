import Foundation
import IdentifiedCollections

// MARK: - DefaultValueProvider
/// An utility property wrapper allowing to specify a default value if the decoded value is missing or nil

/// Provides the Type of the decoded value, also its default value
protocol DefaultValueProvider {
	associatedtype Value: Codable
	static var defaultValue: Value { get }
}

// MARK: - DefaultCodable
enum DefaultCodable {
	/// The property wrapper itself.
	/// Need to make use of the tagging with the protocol, since the value provided in `init` will not be
	/// accessible when initializing with the decoder.
	@propertyWrapper
	struct Wrapper<Provider: DefaultValueProvider>: Codable {
		typealias Value = Provider.Value
		var wrappedValue = Provider.defaultValue

		init(wrappedValue: Provider.Value = Provider.defaultValue) {
			self.wrappedValue = wrappedValue
		}
	}
}

// MARK: - Default Value Providers
extension DefaultCodable {
	typealias AnyCollection = Codable & EmptyInitializable
	typealias EmptyCollection<Collection: AnyCollection> = Wrapper<Providers.EmptyCollection<Collection>>

	enum Providers {
		enum EmptyCollection<Collection: Codable & EmptyInitializable>: DefaultValueProvider {
			static var defaultValue: Collection { .init() }
		}
	}
}

// MARK: - Set + EmptyInitializable
extension Set: EmptyInitializable {}

// MARK: - OrderedSet + EmptyInitializable
extension OrderedSet: EmptyInitializable {}

// MARK: - IdentifiedArray + EmptyInitializable
extension IdentifiedArray: EmptyInitializable where Element: Identifiable, ID == Element.ID {
	init() {
		self.init(id: \.id)
	}
}

// MARK: - Decoding
extension DefaultCodable.Wrapper {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		wrappedValue = try container.decode(Value.self)
	}
}

extension KeyedDecodingContainer {
	func decode<T>(
		_ type: DefaultCodable.Wrapper<T>.Type,
		forKey key: Key
	) throws -> DefaultCodable.Wrapper<T> {
		try decodeIfPresent(type, forKey: key) ?? .init()
	}
}

// MARK: - Encoding
extension KeyedEncodingContainer {
	mutating func encode(_ value: DefaultCodable.Wrapper<some Any>, forKey key: Key) throws {
		try encode(value.wrappedValue, forKey: key)
	}
}

// MARK: - DefaultCodable.Wrapper + Equatable
extension DefaultCodable.Wrapper: Equatable where Provider.Value: Equatable {}

// MARK: - DefaultCodable.Wrapper + Hashable
extension DefaultCodable.Wrapper: Hashable where Provider.Value: Hashable {}

// MARK: - DefaultCodable.Wrapper + Sendable
extension DefaultCodable.Wrapper: Sendable where Provider.Value: Sendable {}
