import Foundation

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol: Identifiable, Hashable where ID: BaseFactorSourceIDProtocol {
	var kind: FactorSourceKind { get }
	var common: FactorSource.Common { get set }
	func embed() -> FactorSource
}

extension BaseFactorSourceProtocol {
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
