import WebRTC

// MARK: - PeerConnectionIdTag
/// The Established Peer Connection ID.
enum PeerConnectionIdTag {}
typealias PeerConnectionID = Tagged<PeerConnectionIdTag, String>

// MARK: - PeerConnectionID + Sendable
extension PeerConnectionID: Sendable {}

extension LinkConnectionQRData {
	func hasValidSignature() -> Bool {
		let signature = SignatureWithPublicKey.ed25519(
			publicKey: publicKeyOfOtherParty,
			signature: signature
		)

		return signature.isValid(password.messageHash)
	}
}
