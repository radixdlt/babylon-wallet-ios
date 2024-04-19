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

extension Sargon.Account {
	public var accountAddress: AccountAddress {
		address
	}

	public mutating func hide() {
		flags.append(.deletedByUser)
	}

	public mutating func unhide() {
		flags.remove(element: .deletedByUser)
	}
}

extension Sargon.Accounts {
	public var nonHidden: IdentifiedArrayOf<Sargon.Account> {
		filter(not(\.isHidden)).asIdentified()
	}

	public var hidden: IdentifiedArrayOf<Sargon.Account> {
		filter(\.isHidden).asIdentified()
	}
}
