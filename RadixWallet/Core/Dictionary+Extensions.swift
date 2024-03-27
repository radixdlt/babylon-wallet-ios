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
