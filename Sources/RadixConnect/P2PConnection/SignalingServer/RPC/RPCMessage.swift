import P2PModels
import Prelude

// MARK: - RPCMessage
public struct RPCMessage: Codable, Sendable, Hashable, CustomStringConvertible {
	public let requestId: String
	public let encryptedPayload: HexCodable
	private let connectionId: String
	public var connectionID: P2PConnectionID { try! .init(data: .init(hex: connectionId)) }
	public let method: RPCMethod
	public let source: ClientSource

	public init(
		method: RPCMethod,
		source: ClientSource,
		connectionId: P2PConnectionID,
		requestId: String,
		encryptedPayload: HexCodable
	) {
		self.method = method
		self.source = source
		self.connectionId = connectionId.data.hex()
		self.requestId = requestId
		self.encryptedPayload = encryptedPayload
	}
}

public extension RPCMessage {
	// Potentially dangerous since caller can pass incorrect data. e.g.
	// `RPCMessage(encryption: Data(), of: unencrypted)` which is obviously
	// not correct.
	init(
		encryption encryptedPayload: Data,
		of unencrypted: RPCMessageUnencrypted
	) {
		self.init(
			method: unencrypted.method,
			source: unencrypted.source,
			connectionId: unencrypted.connectionId,
			requestId: unencrypted.requestId,
			encryptedPayload: .init(data: encryptedPayload)
		)
	}
}

public extension RPCMessage {
	var description: String {
		"""
		connectionID: \(connectionId),
		requestId: \(requestId),
		source: \(source),
		method: \(method),
		encryptedPayload: #\(encryptedPayload.data.count) bytes"
		"""
	}
}

#if DEBUG
public extension RPCMessage {
	static let placeholder = Self.placeholder()
	static func placeholder(requestId: String = "0") -> Self {
		.init(method: .offer,
		      source: .mobileWallet,
		      connectionId: .deadbeef32Bytes,
		      requestId: requestId,
		      encryptedPayload: .deadbeef32Bytes)
	}
}
#endif // DEBUG
