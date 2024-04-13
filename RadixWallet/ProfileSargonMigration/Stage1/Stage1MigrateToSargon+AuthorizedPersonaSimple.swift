import Foundation
import Sargon

extension AuthorizedPersonaSimple: Identifiable {
	public typealias ID = IdentityAddress
	public var id: ID {
		identityAddress
	}

	public typealias SharedAccounts = SharedToDappWithPersonaAccountAddresses
}
