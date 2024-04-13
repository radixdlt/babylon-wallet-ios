import Foundation
import Sargon

extension Sargon.Account {
	public typealias ID = AccountAddress
	public var id: ID {
		address
	}

	public var networkID: NetworkID {
		networkId
	}
}

// MARK: - Sargon.Account + EntityBaseProtocol
extension Sargon.Account: EntityBaseProtocol {}

// MARK: - Sargon.Account + Comparable
extension Sargon.Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

extension Sargon.Account {
	var derivationIndex: HDPathValue {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.index
		}
	}
}
