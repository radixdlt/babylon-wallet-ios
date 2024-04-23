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

	public static func common(
		cryptoParameters: FactorSourceCryptoParameters
	) throws -> FactorSourceCommon {
		@Dependency(\.date) var date
		return .init(
			cryptoParameters: cryptoParameters,
			addedOn: date(),
			lastUsedOn: date(),
			flags: []
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

// MARK: - FactorSource + BaseFactorSourceProtocol
extension FactorSource: BaseFactorSourceProtocol {
	public var common: FactorSourceCommon {
		get { property(\.common) }
		set {
			update(\.common, to: newValue)
		}
	}

	// Compiler crash if we try to use `private func property<Property>(_ keyPath: KeyPath<any FactorSourceProtocol, Property>) -> Property {
	// and use `property(\.id).embed()
	// :/
	public var id: ID {
		switch self {
		case let .device(factorSource): factorSource.id.embed()
		case let .ledger(factorSource): factorSource.id.embed()
		}
	}

//	public var kind: FactorSourceKind {
//		property(\.kind)
//	}

	public func embed() -> FactorSource {
		self
	}

	public mutating func update<Property>(
		_ writableKeyPath: WritableKeyPath<any FactorSourceProtocol, Property>,
		to newValue: Property
	) {
		switch self {
		case var .device(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .ledger(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()
		}
	}

	private func property<Property>(_ keyPath: KeyPath<any BaseFactorSourceProtocol, Property>) -> Property {
		switch self {
		case let .device(factorSource): factorSource[keyPath: keyPath]
		case let .ledger(factorSource): factorSource[keyPath: keyPath]
		}
	}
}
