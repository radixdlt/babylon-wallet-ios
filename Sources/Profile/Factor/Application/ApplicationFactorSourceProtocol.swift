import Prelude

// MARK: - _ApplicationFactorSource
public protocol _ApplicationFactorSource:
	_FactorSourceProtocol,
	Sendable,
	Hashable,
	Identifiable
{
	static var assertedKind: FactorSourceKind { get }
	static var assertedParameters: FactorSource.Parameters? { get }
	var factorSource: FactorSource { get }
	init(factorSource: FactorSource) throws
}

extension _ApplicationFactorSource {
	public static var assertedParameters: FactorSource.Parameters? { nil }
	public var kind: FactorSourceKind { factorSource.kind }
	public var id: FactorSourceID { factorSource.id }
	public var label: FactorSource.Label { factorSource.label }
	public var description: FactorSource.Description { factorSource.description }
	public var parameters: FactorSource.Parameters { factorSource.parameters }
	public var addedOn: Date { factorSource.addedOn }
	public var lastUsedOn: Date { factorSource.lastUsedOn }
	public var storage: FactorSource.Storage? { factorSource.storage }

	public static func validating(factorSource: FactorSource) throws -> FactorSource {
		guard
			factorSource.kind == Self.assertedKind
		else {
			throw DisrepancyFactorSourceWrongKind(
				expected: Self.assertedKind,
				actual: factorSource.kind
			)
		}
		if let expectedParameters = Self.assertedParameters, factorSource.parameters != expectedParameters {
			throw DisrepancyFactorSourceWrongParameters(
				expected: expectedParameters,
				actual: factorSource.parameters
			)
		}
		return factorSource
	}

	public var supportsOlympia: Bool {
		parameters.supportsOlympia
	}
}

// MARK: - DisrepancyFactorSourceWrongKind
public struct DisrepancyFactorSourceWrongKind: Swift.Error {
	public let expected: FactorSourceKind
	public let actual: FactorSourceKind
}

// MARK: - DisrepancyFactorSourceWrongParameters
public struct DisrepancyFactorSourceWrongParameters: Swift.Error {
	public let expected: FactorSource.Parameters
	public let actual: FactorSource.Parameters
}
