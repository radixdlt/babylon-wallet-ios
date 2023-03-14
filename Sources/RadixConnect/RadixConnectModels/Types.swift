import Prelude

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
