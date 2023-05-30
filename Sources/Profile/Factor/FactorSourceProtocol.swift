import Prelude

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol: BaseFactorSourceProtocol, Sendable, Hashable, Codable, Identifiable {
	static var kind: FactorSourceKind { get }
	static var casePath: CasePath<FactorSource, Self> { get }
}

extension FactorSourceProtocol {
	public typealias ID = FactorSourceID
	public var id: ID { common.id }
	public var kind: FactorSourceKind { Self.kind }
	public var casePath: CasePath<FactorSource, Self> { Self.casePath }
}

extension FactorSourceProtocol {
	public func embed() -> FactorSource {
		casePath.embed(self)
	}

	public static func extract(from factorSource: FactorSource) -> Self? {
		casePath.extract(from: factorSource)
	}
}
