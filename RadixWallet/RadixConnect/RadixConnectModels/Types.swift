import WebRTC

// MARK: - PeerConnectionIdTag
/// The Established Peer Connection ID.
public enum PeerConnectionIdTag {}
public typealias PeerConnectionID = Tagged<PeerConnectionIdTag, String>

// MARK: Sendable
extension PeerConnectionID: Sendable {}

// MARK: - ConnectionPasswordTag
/// The ConnectionPassword to be used to connect to the SignalingServer.
public enum ConnectionPasswordTag {}
public typealias ConnectionPassword = Tagged<ConnectionPasswordTag, HexCodable32Bytes>

#if DEBUG
extension ConnectionPassword {
	public static let placeholder = try! Self(.init(.deadbeef32Bytes))
}
#endif // DEBUG

// MARK: - ConnectionPublicKeyTag
public enum ConnectionPublicKeyTag {}
public typealias ConnectionPublicKey = Tagged<ConnectionPublicKeyTag, HexCodable32Bytes>

#if DEBUG
extension ConnectionPublicKey {
	public static let placeholder = try! Self(.init(.deadbeef32Bytes))
}
#endif // DEBUG

// MARK: - LinkConnectionQRData
public struct LinkConnectionQRData: Sendable, Hashable, Decodable {
	public var purpose: ConnectionPurpose

	public let password: ConnectionPassword

	public let publicKey: ConnectionPublicKey

	public let signature: HexCodable
}

#if DEBUG
extension LinkConnectionQRData {
	public static let placeholder = Self(
		purpose: .general,
		password: .placeholder,
		publicKey: .placeholder,
		signature: HexCodable(data: Data())
	)
}
#endif

// MARK: - ConnectionPurpose
public enum ConnectionPurpose: String, Sendable, Codable, UnknownCaseDecodable {
	case general
	case unknown
}
