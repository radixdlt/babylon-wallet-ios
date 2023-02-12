import ClientPrelude

// MARK: - P2P.RequestFromClient
extension P2P {
	// MARK: - RequestFromClient
	public struct RequestFromClient: Sendable, Hashable {
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
extension P2PClient {
	public static let previewValue: Self = .init(
		connectionPassword: .placeholder,
		displayName: "PreviewValue"
	)
}

extension P2PConnections.IncomingMessage {
	public static let previewValue = Self(messagePayload: .deadbeef32Bytes, messageID: "previewValue", messageHash: .deadbeef32Bytes)
}

extension P2P.RequestFromClient {
	public static let previewValue = Self.previewValueOneTimeAccountAccess
	public static let previewValueOneTimeAccountAccess: Self = .init(
		originalMessage: .previewValue,
		interaction: .previewValueOneTimeAccount,
		client: .previewValue
	)
	public static let previewValueSignTXRequest: Self = .init(
		originalMessage: .previewValue,
		interaction: .previewValueSignTX,
		client: .previewValue
	)
}
#endif // DEBUG
