import WebRTC

// MARK: - PeerConnectionIdTag
/// The Established Peer Connection ID.
public enum PeerConnectionIdTag {}
public typealias PeerConnectionID = Tagged<PeerConnectionIdTag, String>

// MARK: Sendable
extension PeerConnectionID: Sendable {}
