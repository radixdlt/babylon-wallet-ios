import Foundation

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol {
	var kind: FactorSourceKind { get }
	var common: FactorSource.Common { get set }
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
}
