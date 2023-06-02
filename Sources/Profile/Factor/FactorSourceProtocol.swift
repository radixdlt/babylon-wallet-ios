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
	public static func id(hash: some DataProtocol) throws -> ID {
		try .init(factorSourceKind: kind, hash: Data(hash))
	}

	public static func common(
		hashForID: some DataProtocol,
		isOlympiaCompatible: Bool = false
	) throws -> FactorSource.Common {
		@Dependency(\.date) var date
		return try .init(
			id: Self.id(hash: hashForID),
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
