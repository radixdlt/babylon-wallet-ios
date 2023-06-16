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
}

extension ExpressibleByRadixEngineValues {
	public init(@ValuesBuilder buildValues: () throws -> [any ValueProtocol]) rethrows {
		try self.init(buildValues())
	}
}
