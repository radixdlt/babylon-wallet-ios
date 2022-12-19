import Foundation
import Peer
import Profile

// MARK: - P2P.RequestFromClient
public extension P2P {
	// MARK: - RequestFromClient
	struct RequestFromClient: Sendable, Hashable, Identifiable {
		public let originalMessage: Peer.IncomingMessage

		public let requestFromDapp: FromDapp.Request
		public let client: P2PClient

		public init(
			originalMessage: Peer.IncomingMessage,
			requestFromDapp: FromDapp.Request,
			client: P2PClient
		) throws {
			self.originalMessage = originalMessage
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

extension Peer.IncomingMessage {
	static let placeholder = Self(messagePayload: .deadbeef32Bytes, messageID: "placeholder", messageHash: .deadbeef32Bytes)
}

public extension P2P.RequestFromClient {
	static let placeholder = Self.placeholderOneTimeAccountAccess
	static let placeholderOneTimeAccountAccess: Self = try! .init(
		originalMessage: .placeholder,
		requestFromDapp: .placeholderOneTimeAccount,
		client: .placeholder
	)
	static let placeholderSignTXRequest: Self = try! .init(
		originalMessage: .placeholder,
		requestFromDapp: .placeholderSignTX,
		client: .placeholder
	)
}
#endif // DEBUG
