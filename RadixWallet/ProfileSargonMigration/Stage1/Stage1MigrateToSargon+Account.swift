import Foundation
import Sargon

// MARK: - Sargon.Account + EntityBaseProtocol
extension Sargon.Account: EntityBaseProtocol {}

// MARK: - Sargon.Account + Comparable
extension Sargon.Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

extension Sargon.Account {
	public static let nameMaxLength = 30

	public var derivationIndex: HDPathValue {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.index
		}
	}

	public var isLegacy: Bool {
		address.isLegacy
	}

	public var isLedgerControlled: Bool {
		switch self.securityState {
		case let .unsecured(control):
			control.transactionSigning.factorSourceID.kind == .ledgerHqHardwareWallet
		}
	}
}
