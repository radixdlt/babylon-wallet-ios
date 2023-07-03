import Foundation

// MARK: - FactorOfTierProtocol
public protocol FactorOfTierProtocol {
	var factorSourceKind: FactorSourceKind { get }
}

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol: FactorOfTierProtocol, Identifiable, Hashable where ID: BaseFactorSourceIDProtocol {
	var kind: FactorSourceKind { get }
	var common: FactorSource.Common { get set }
	func embed() -> FactorSource
}

extension BaseFactorSourceProtocol {
	public var factorSourceKind: FactorSourceKind {
		kind
	}

	public var cryptoParameters: FactorSource.CryptoParameters {
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
}

extension BaseFactorSourceProtocol {
	public mutating func flag(_ flag: FactorSourceFlag) {
		common.flags.append(flag)
	}

	public var isFlaggedForDeletion: Bool {
		common.flags.contains(.deletedByUser)
	}
}
