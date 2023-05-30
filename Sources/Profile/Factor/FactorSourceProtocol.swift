import CasePaths
import Prelude

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol:
	BaseFactorSourceProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable where ID == FactorSourceID
{
	static var kind: FactorSourceKind { get }
	static var casePath: CasePath<FactorSource, Self> { get }
}

extension FactorSourceProtocol {
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
