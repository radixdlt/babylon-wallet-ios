import Foundation

internal extension P2P.FromDapp {
	// Used by Responses and Requests
	enum Discriminator: String, Codable, CaseIterable, Hashable {
		case oneTimeAccountsRead
		case sendTransactionWrite
	}
}
