import Foundation
import P2PModels

// MARK: - RPCMessageUnencrypted
public struct RPCMessageUnencrypted: Sendable, Hashable {
	public let requestId: String
	public let connectionId: P2PConnectionID
	public let method: RPCMethod
	public let source: ClientSource
	public let unencryptedPayload: Data

	public init(
		method: RPCMethod,
		source: ClientSource,
		connectionId: P2PConnectionID,
		requestId: String,
		unencryptedPayload: Data
	) {
		self.method = method
		self.source = source
		self.connectionId = connectionId
		self.requestId = requestId

		self.unencryptedPayload = unencryptedPayload
	}
}

#if DEBUG
extension P2PConnectionID {
	public static let deadbeef32Bytes: Self = try! .init(data: .deadbeef32Bytes)
}

extension RPCMessageUnencrypted {
	public static func placeholder(
		method: RPCMethod = .answer,
		source: ClientSource = .mobileWallet,
		connectionId: P2PConnectionID = .deadbeef32Bytes,
		requestId: String = .deadbeef32Bytes,
		unencryptedPayload: Data = .deadbeef32Bytes
	) -> Self {
		.init(
			method: method,
			source: source,
			connectionId: connectionId,
			requestId: requestId,
			unencryptedPayload: unencryptedPayload
		)
	}

	public static let placeholder = Self.placeholder()
}
#endif // DEBUG
