import Foundation

// MARK: - ExpressibleByRadixEngineValues
public protocol ExpressibleByRadixEngineValues: ExpressibleByArrayLiteral {
	init(values: [Value_])
}

extension ExpressibleByRadixEngineValues {
	public init(_ values: [any ValueProtocol]) {
		self.init(values: values.map { $0.embedValue() })
	}

	public init(arrayLiteral elements: Value_...) {
		self.init(values: elements)
	}
}

// MARK: - ValuesBuilder
@resultBuilder
public struct ValuesBuilder {}
extension ValuesBuilder {
	public static func buildBlock(_ values: any ValueProtocol...) -> [any ValueProtocol] {
		values
	}

	public static func buildBlock(_ value: any ValueProtocol) -> [any ValueProtocol] {
		[value]
	}

	public static func buildBlock(_ value: any ValueProtocol) -> any ValueProtocol {
		value
	}
}

// MARK: - SpecificValuesBuilder
@resultBuilder
public struct SpecificValuesBuilder {}
extension SpecificValuesBuilder {
	public static func buildBlock(_ values: Value_...) -> [Value_] {
		values
	}

	public static func buildBlock(_ value: Value_) -> [Value_] {
		[value]
	}

	public static func buildBlock(_ value: Value_) -> Value_ {
		value
	}
}

extension ExpressibleByRadixEngineValues {
	public init(@ValuesBuilder buildValues: () throws -> [any ValueProtocol]) rethrows {
		self.init(try buildValues())
	}

	public init(@SpecificValuesBuilder buildValues: () throws -> [Value_]) rethrows {
		self.init(values: try buildValues())
	}

	public init(@SpecificValuesBuilder buildValue: () throws -> Value_) rethrows {
		self.init(values: [try buildValue()])
	}
}
