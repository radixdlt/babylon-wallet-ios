import Foundation

// MARK: - WebRTCAnswer
public struct WebRTCAnswer: WebRTCPrimitiveProtocol {
	/// The [Session Description Protocol][sdp] string of this WebRTC `WebRTCAnswer`, originating an `RTCPeerConnection`,
	/// created by its [`createAnswer`][createAnswer] method.
	///
	/// [sdp]: https://developer.mozilla.org/en-US/docs/Glossary/SDP
	/// [createAnswer]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/createAnswer
	///
	public let sdp: String

	public init(sdp: String) {
		self.sdp = sdp
	}
}

extension WebRTCAnswer {
	public var description: String {
		description(includeTypeName: true)
	}

	public func description(includeTypeName: Bool) -> String {
		let props = "sdp: \(sdp)"
		guard includeTypeName else {
			return props
		}
		return "Answer(\(props))"
	}
}

#if DEBUG
extension WebRTCAnswer {
	public static let placeholder = Self(sdp: "<ANSWER SDP GOES HERE>")
}
#endif // DEBUG
