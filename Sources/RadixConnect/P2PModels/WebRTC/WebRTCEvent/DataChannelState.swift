import Foundation

// MARK: - DataChannelState
/// The read-only RTCDataChannel property readyState returns a string which indicates
/// the state of the data channel's underlying data connection.
public enum DataChannelState: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// We are in the process of creating the underlying
	/// data transport; this is the state of a new RTCDataChannel after being
	/// created by RTCPeerConnection.createDataChannel(), on the peer which
	/// started the connection process.
	case connecting

	/// The underlying data transport has been established and data
	/// can be transferred bidirectionally across it. This is the default
	/// state of a new RTCDataChannel created by the WebRTC layer when
	/// the remote peer created the channel and delivered it to the site
	/// or app in a datachannel event.
	case open

	/// The process of closing the underlying data transport has begun.
	/// It is no longer possible to queue new messages to be sent, but
	/// previously queued messages may still be send or received before
	/// entering the `closed` state.
	case closing

	/// The underlying data transport has closed, or the attempt to make the connection `failed`.
	case closed
}

extension DataChannelState {
	public var description: String {
		rawValue
	}
}
