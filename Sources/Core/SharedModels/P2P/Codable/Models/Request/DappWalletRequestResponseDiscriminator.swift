import Foundation

internal extension P2P.FromDapp {
	// Used by Responses and Requests
	enum Discriminator: String, Codable {
		case ongoingAccountAddresses
		case signTransaction = "sendTransaction"
	}
}
