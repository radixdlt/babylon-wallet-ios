import Foundation

// MARK: - ExpressibleByRadixEngineValues
public protocol ExpressibleByRadixEngineValues: ExpressibleByArrayLiteral {
	init(values: [Value_])
}

public extension ExpressibleByRadixEngineValues {
	init(_ values: [any ValueProtocol]) {
		self.init(values: values.map { $0.embedValue() })
	}

	init(arrayLiteral elements: Value_...) {
		self.init(values: elements)
	}
}

// MARK: - ValuesBuilder
@resultBuilder
public struct ValuesBuilder {}
public extension ValuesBuilder {
	static func buildBlock(_ values: any ValueProtocol...) -> [any ValueProtocol] {
		values
	}

	static func buildBlock(_ value: any ValueProtocol) -> [any ValueProtocol] {
		[value]
	}

	static func buildBlock(_ value: any ValueProtocol) -> any ValueProtocol {
		value
	}
}

// MARK: - SpecificValuesBuilder
@resultBuilder
public struct SpecificValuesBuilder {}
public extension SpecificValuesBuilder {
	static func buildBlock(_ values: Value_...) -> [Value_] {
		values
	}

	static func buildBlock(_ value: Value_) -> [Value_] {
		[value]
	}

	static func buildBlock(_ value: Value_) -> Value_ {
		value
	}
}

public extension ExpressibleByRadixEngineValues {
	init(@ValuesBuilder buildValues: () throws -> [any ValueProtocol]) rethrows {
		self.init(try buildValues())
	}

	init(@SpecificValuesBuilder buildValues: () throws -> [Value_]) rethrows {
		self.init(values: try buildValues())
	}

	init(@SpecificValuesBuilder buildValue: () throws -> Value_) rethrows {
		self.init(values: [try buildValue()])
	}
}
