import EngineToolkit

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol:
	BaseFactorSourceProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable where ID: FactorSourceIDProtocol
{
	static var kind: FactorSourceKind { get }
	static var casePath: CasePath<FactorSource, Self> { get }
	var id: ID { get }
}

extension FactorSourceProtocol {
	public var kind: FactorSourceKind { Self.kind }
	public var casePath: CasePath<FactorSource, Self> { Self.casePath }

	public static func common(
		isOlympiaCompatible: Bool = false
	) throws -> FactorSource.Common {
		@Dependency(\.date) var date
		return .init(
			cryptoParameters: isOlympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			addedOn: date(),
			lastUsedOn: date()
		)
	}
}

extension FactorSourceProtocol {
	public func embed() -> FactorSource {
		casePath.embed(self)
	}

	public static func extract(from factorSource: FactorSource) -> Self? {
		casePath.extract(from: factorSource)
	}
}
