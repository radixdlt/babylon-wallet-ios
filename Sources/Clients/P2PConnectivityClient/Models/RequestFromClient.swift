import ClientPrelude

// MARK: - P2P.RequestFromClient
public extension P2P {
	// MARK: - RequestFromClient
	struct RequestFromClient: Sendable, Hashable {
		public let originalMessage: P2PConnections.IncomingMessage

		public let interaction: FromDapp.WalletInteraction
		public let client: P2PClient

		public init(
			originalMessage: P2PConnections.IncomingMessage,
			interaction: FromDapp.WalletInteraction,
			client: P2PClient
		) {
			self.originalMessage = originalMessage
			self.interaction = interaction
			self.client = client
		}
	}
}

// MARK: - InvalidRequestFromDapp
public struct InvalidRequestFromDapp: Swift.Error, Equatable, CustomStringConvertible {
	public let description: String
}

#if DEBUG
public extension P2PClient {
	static let previewValue: Self = try! .init(
		connectionPassword: .placeholder,
		displayName: "PreviewValue"
	)
}

public extension P2PConnections.IncomingMessage {
	static let previewValue = Self(messagePayload: .deadbeef32Bytes, messageID: "previewValue", messageHash: .deadbeef32Bytes)
}

public extension P2P.RequestFromClient {
	static let previewValue = Self.previewValueOneTimeAccountAccess
	static let previewValueOneTimeAccountAccess: Self = .init(
		originalMessage: .previewValue,
		interaction: .previewValueOneTimeAccount,
		client: .previewValue
	)
	static let previewValueSignTXRequest: Self = .init(
		originalMessage: .previewValue,
		interaction: .previewValueSignTX,
		client: .previewValue
	)
}
#endif // DEBUG
