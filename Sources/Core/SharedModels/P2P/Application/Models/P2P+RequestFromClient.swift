import Foundation
import Peer
import Profile

// MARK: - P2P.RequestFromClient
public extension P2P {
	// MARK: - RequestFromClient
	struct RequestFromClient: Sendable, Hashable, Identifiable {
		/// This message id is used to send MsgReceivedConfirmation/MsgReadReceipt back to
		/// peer (Wallet SDK, not necessarily dApp). Not to be confised with `requestFromDapp.id`
		/// which is an Application Layer request identifier, this is more a Transport Layer identifer.
		public let msgReceivedReceiptID: Peer.MessageID

		public let requestFromDapp: FromDapp.Request
		public let client: P2PClient

		public init(
			msgReceivedReceiptID: Peer.MessageID,
			requestFromDapp: FromDapp.Request,
			client: P2PClient
		) throws {
			self.msgReceivedReceiptID = msgReceivedReceiptID
			self.requestFromDapp = requestFromDapp
			self.client = client
		}
	}
}

public extension P2P.RequestFromClient {
	typealias ID = P2P.FromDapp.Request.ID

	/// Not to be confused with `msgReceivedReceiptID` (which is a transport layer msg ID), whereas
	/// this is an Application Layer identifer.
	var id: ID {
		requestFromDapp.id
	}
}

// MARK: - InvalidRequestFromDapp
public struct InvalidRequestFromDapp: Swift.Error, Equatable, CustomStringConvertible {
	public let description: String
}

#if DEBUG
public extension P2PClient {
	static let placeholder: Self = try! .init(
		displayName: "Placeholder",
		connectionPassword: Data(hexString: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
	)
}

public extension P2P.RequestFromClient {
	static let placeholder = Self.placeholderOneTimeAccountAccess
	static let placeholderOneTimeAccountAccess: Self = try! .init(
		msgReceivedReceiptID: "placeholder",
		requestFromDapp: .placeholderOneTimeAccount,
		client: .placeholder
	)
	static let placeholderSignTXRequest: Self = try! .init(
		msgReceivedReceiptID: "placeholder",
		requestFromDapp: .placeholderSignTX,
		client: .placeholder
	)
}
#endif // DEBUG
