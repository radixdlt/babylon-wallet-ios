import Foundation

public enum AddressOfAccountOrPersona {
	case account(AccountAddress)
	case persona(IdentityAddress)

	public var address: Address {
		switch self {
		case let .account(address):
			address.asGeneral
		case let .persona(address):
			address.asGeneral
		}
	}
}
