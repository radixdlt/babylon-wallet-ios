import P2PConnection
import Prelude
import Profile

// MARK: - P2P.RequestFromClient
public extension P2P {
	// MARK: - RequestFromClient
	struct RequestFromClient: Sendable, Hashable, Identifiable {
		public let originalMessage: P2PConnections.IncomingMessage

		public let requestFromDapp: FromDapp.Request
		public let client: P2PClient

		public init(
			originalMessage: P2PConnections.IncomingMessage,
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
	static let previewValue: Self = try! .init(
		connectionPassword: ConnectionPassword(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"),
		displayName: "Placeholder"
	)
}

public extension P2PConnections.IncomingMessage {
	static let previewValue = Self(messagePayload: .deadbeef32Bytes, messageID: "previewValue", messageHash: .deadbeef32Bytes)
}

public extension P2P.RequestFromClient {
	static let previewValue = Self.previewValueOneTimeAccountAccess
	static let previewValueOneTimeAccountAccess: Self = try! .init(
		originalMessage: .previewValue,
		requestFromDapp: .previewValueOneTimeAccount,
		client: .previewValue
	)
	static let previewValueSignTXRequest: Self = try! .init(
		originalMessage: .previewValue,
		requestFromDapp: .previewValueSignTX,
		client: .previewValue
	)
}
#endif // DEBUG
