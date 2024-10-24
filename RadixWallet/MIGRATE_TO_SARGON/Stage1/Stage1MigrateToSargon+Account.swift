import Foundation
import Sargon

// MARK: - Account + Comparable
extension Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

extension Account {
	static let nameMaxLength = 30

	var derivationIndex: HDPathValue {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.nonHardenedIndex
		case let .securified(sec): fatalError("Implement")
		}
	}

	var isLegacy: Bool {
		address.isLegacy
	}

	var isLedgerControlled: Bool {
		switch self.securityState {
		case let .unsecured(control):
			control.transactionSigning.factorSourceID.kind == .ledgerHqHardwareWallet
		case let .securified(sec): fatalError("Implement")
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
