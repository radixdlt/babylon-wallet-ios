import Prelude

// MARK: - ClientIDTag
public enum RemoteClientIDTag {}
public typealias RemoteClientID = Tagged<RemoteClientIDTag, String>

public enum PeerConnectionIdTag {}
public typealias PeerConnectionId = Tagged<PeerConnectionIdTag, RemoteClientID>

extension PeerConnectionId: Sendable {}

public enum ConnectionPasswordTag {}
public typealias ConnectionPassword = Tagged<ConnectionPasswordTag, HexCodable32Bytes>
