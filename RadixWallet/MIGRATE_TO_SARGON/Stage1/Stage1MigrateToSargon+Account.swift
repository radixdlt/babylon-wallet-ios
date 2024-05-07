import Foundation
import Sargon

// MARK: - Account + Comparable
extension Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

extension Account {
	public static let nameMaxLength = 30

	public var derivationIndex: HDPathValue {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.nonHardenedIndex
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

extension Account {
	
	public var accountAddress: AccountAddress {
		address
	}

	public mutating func hide() {
		flags.append(.deletedByUser)
	}

	public mutating func unhide() {
		entityFlags.remove(.deletedByUser)
	}
}

extension Accounts {
	public var nonHidden: Accounts {
		filter(not(\.isHidden))
	}

	public var hidden: Accounts {
		filter(\.isHidden)
	}
}


extension [Account] {
	public var nonHidden: Accounts {
		asIdentified().nonHidden
	}

	public var hidden: Accounts {
		asIdentified().hidden
	}
}
