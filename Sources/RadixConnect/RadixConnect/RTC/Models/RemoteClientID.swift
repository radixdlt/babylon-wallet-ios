import Tagged

// MARK: - RemoteClientIDTag
/// ID of the remote client to negotiate the Peer Connection with.
enum RemoteClientIDTag {}
typealias RemoteClientID = Tagged<RemoteClientIDTag, String>
