import Foundation

extension Dictionary {
	func mapKeys<U>(_ f: (Key) throws -> U) throws -> [U: Value] {
		try mapKeyValues(f, fValue: { $0 })
	}

	func mapKeyValues<U, T>(_ fKey: (Key) throws -> U, fValue: (Value) throws -> T) throws -> [U: T] {
		try .init(
			map {
				try (fKey($0.key), fValue($0.value))
			},
			uniquingKeysWith: { first, _ in first }
		)
	}
}

extension Dictionary {
	// Custom initializer that throws if there are duplicate keys
	init(keysWithValues: [(Key, Value)]) throws {
		self = [:]

		for (key, value) in keysWithValues {
			if self[key] != nil {
				throw DictionaryDuplicateKeyError()
			}
			self[key] = value
		}
	}

	struct DictionaryDuplicateKeyError: Error {}
}

extension OrderedDictionary {
	// Custom initializer that throws if there are duplicate keys
	init(keysWithValues: [(Key, Value)]) throws {
		self = OrderedDictionary()

		for (key, value) in keysWithValues {
			if self[key] != nil {
				throw OrderedDictionaryDuplicateKeyError()
			}
			self[key] = value
		}
	}

	struct OrderedDictionaryDuplicateKeyError: Error {}
}

extension OrderedDictionary {
	var asDictionary: [Key: Value] {
		var dictionary = [Key: Value]()

		for (key, value) in self {
			dictionary[key] = value
		}

		return dictionary
	}
}
