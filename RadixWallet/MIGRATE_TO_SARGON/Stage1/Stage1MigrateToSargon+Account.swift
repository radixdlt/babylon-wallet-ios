import Foundation
import Sargon

// MARK: - Account + Comparable
extension Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

// MARK: - HdPathComponent + Comparable
extension HdPathComponent: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.indexInGlobalKeySpace() < rhs.indexInGlobalKeySpace()
	}
}

extension Account {
	static let nameMaxLength = 30

	var derivationIndex: HdPathComponent {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.lastPathComponent
		}
	}

	var isLegacy: Bool {
		address.isLegacy
	}

	var isLedgerControlled: Bool {
		switch self.securityState {
		case let .unsecured(control):
			control.transactionSigning.factorSourceID.kind == .ledgerHqHardwareWallet
		}
	}
}

extension Account {
	var accountAddress: AccountAddress {
		address
	}

	mutating func hide() {
		flags.append(.deletedByUser)
	}

	mutating func unhide() {
		entityFlags.remove(.deletedByUser)
	}
}

extension Accounts {
	var nonHidden: Accounts {
		filter(not(\.isHidden))
	}

	var hidden: Accounts {
		filter(\.isHidden)
	}
}

extension [Account] {
	var nonHidden: Accounts {
		asIdentified().nonHidden
	}

	var hidden: Accounts {
		asIdentified().hidden
	}
}
