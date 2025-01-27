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
		flags.append(.hiddenByUser)
	}

	mutating func unhide() {
		entityFlags.remove(.hiddenByUser)
	}
}

extension Accounts {
	var nonDeleted: Accounts {
		filter(not(\.isDeleted))
	}

	var nonHidden: Accounts {
		filter(not(\.isHidden))
	}

	var hidden: Accounts {
		filter(\.isHidden)
	}
}

extension [Account] {
	var nonDeleted: Accounts {
		asIdentified().nonDeleted
	}

	var nonHidden: Accounts {
		asIdentified().nonHidden
	}

	var hidden: Accounts {
		asIdentified().hidden
	}
}
