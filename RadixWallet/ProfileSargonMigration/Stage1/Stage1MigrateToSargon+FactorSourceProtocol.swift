import Foundation
import Sargon

// MARK: - FactorOfTierProtocol
public protocol FactorOfTierProtocol {
	var factorSourceKind: FactorSourceKind { get }
}

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol: FactorOfTierProtocol, Identifiable, Hashable {
	var kind: FactorSourceKind { get }
	var common: FactorSourceCommon { get set }
	func embed() -> FactorSource
}

extension BaseFactorSourceProtocol {
	public var factorSourceKind: FactorSourceKind {
		kind
	}

	public var cryptoParameters: FactorSourceCryptoParameters {
		common.cryptoParameters
	}

	public var addedOn: Date {
		common.addedOn
	}

	public var lastUsedOn: Date {
		common.lastUsedOn
	}

	public var supportsOlympia: Bool {
		cryptoParameters.supportsOlympia
	}

	public var supportsBabylon: Bool {
		cryptoParameters.supportsBabylon
	}
}

extension BaseFactorSourceProtocol {
	public mutating func flag(_ flag: FactorSourceFlag) {
		common.flags.append(flag)
	}

	public var isFlaggedForDeletion: Bool {
		common.flags.contains(.deletedByUser)
	}
}

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol:
	BaseFactorSourceProtocol,
	Sendable,
	Hashable,
//	Codable,
	Identifiable // where ID: FactorSourceIDProtocol
{
	static var kind: FactorSourceKind { get }
	static var casePath: AnyCasePath<FactorSource, Self> { get }
	var id: ID { get }
}

extension FactorSourceProtocol {
	public var kind: FactorSourceKind { Self.kind }
	public var casePath: AnyCasePath<FactorSource, Self> { Self.casePath }

//	public static func common(
//		cryptoParametersPreset: FactorSourceCryptoParameters.Preset
//	) throws -> FactorSourceCommon {
//		@Dependency(\.date) var date
//		return .init(
//			cryptoParameters: cryptoParametersPreset.cryptoParameters,
//			addedOn: date(),
//			lastUsedOn: date()
//		)
//	}
}

extension FactorSourceProtocol {
	public func embed() -> FactorSource {
		casePath.embed(self)
	}

	public static func extract(from factorSource: FactorSource) -> Self? {
		casePath.extract(from: factorSource)
	}
}

// MARK: - DeviceFactorSource + FactorSourceProtocol
extension DeviceFactorSource: FactorSourceProtocol {
	public static var kind: FactorSourceKind { .device }

	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.device
}

// MARK: - LedgerHardwareWalletFactorSource + FactorSourceProtocol
extension LedgerHardwareWalletFactorSource: FactorSourceProtocol {
	public static var kind: FactorSourceKind {
		.ledgerHqHardwareWallet
	}

	public static var casePath: CasePath<FactorSource, Self> = /FactorSource.ledger
}
