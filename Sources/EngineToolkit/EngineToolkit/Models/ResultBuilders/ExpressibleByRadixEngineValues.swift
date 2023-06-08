import Foundation

// MARK: - ExpressibleByRadixEngineValues
public protocol ExpressibleByRadixEngineValues: ExpressibleByArrayLiteral {
	init(values: [ManifestASTValue])
}

extension ExpressibleByRadixEngineValues {
	public init(_ values: [any ValueProtocol]) {
		self.init(values: values.map { $0.embedValue() })
	}

	public init(arrayLiteral elements: ManifestASTValue...) {
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

	#if swift(<5.8)
	public static func buildBlock(_ value: any ValueProtocol) -> any ValueProtocol {
		value
	}
	#endif
}

#if swift(<5.8)

// MARK: - SpecificValuesBuilder
@resultBuilder
public struct SpecificValuesBuilder {}
extension SpecificValuesBuilder {
	public static func buildBlock(_ values: ManifestASTValue...) -> [ManifestASTValue] {
		values
	}

	public static func buildBlock(_ value: ManifestASTValue) -> [ManifestASTValue] {
		[value]
	}

	public static func buildBlock(_ value: ManifestASTValue) -> ManifestASTValue {
		value
	}
}

#endif

extension ExpressibleByRadixEngineValues {
	public init(@ValuesBuilder buildValues: () throws -> [any ValueProtocol]) rethrows {
		try self.init(buildValues())
	}

	#if swift(<5.8)
	public init(@SpecificValuesBuilder buildValues: () throws -> [ManifestASTValue]) rethrows {
		try self.init(values: buildValues())
	}

	public init(@SpecificValuesBuilder buildValue: () throws -> ManifestASTValue) rethrows {
		self.init(values: [try buildValue()])
	}

	#endif
}
