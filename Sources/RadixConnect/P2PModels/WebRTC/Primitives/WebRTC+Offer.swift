import Foundation

// MARK: - WebRTCOffer
public struct WebRTCOffer: WebRTCPrimitiveProtocol {
	/// The [Session Description Protocol][sdp] string of this WebRTC `WebRTCOffer`, originating an `RTCPeerConnection`,
	/// created by its [`createOffer`][createOffer] method.
	///
	/// [sdp]: https://developer.mozilla.org/en-US/docs/Glossary/SDP
	/// [createOffer]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/createOffer
	///
	public let sdp: String
	public init(sdp: String) {
		self.sdp = sdp
	}
}

extension WebRTCOffer {
	public var description: String {
		description(includeTypeName: true)
	}

	public func description(includeTypeName: Bool) -> String {
		let props = "sdp: \(sdp)"
		guard includeTypeName else {
			return props
		}
		return "Offer(\(props))"
	}
}

#if DEBUG
extension WebRTCOffer {
	public static let placeholder = Self(sdp: "<OFFER SDP GOES HERE>")
}
#endif // DEBUG
