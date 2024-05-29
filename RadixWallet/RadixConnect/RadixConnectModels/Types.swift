import WebRTC

// MARK: - PeerConnectionIdTag
/// The Established Peer Connection ID.
public enum PeerConnectionIdTag {}
public typealias PeerConnectionID = Tagged<PeerConnectionIdTag, String>

// MARK: Sendable
extension PeerConnectionID: Sendable {}

extension LinkConnectionQRData {
	public func hasValidSignature() -> Bool {
		let signature = SignatureWithPublicKey.ed25519(
			publicKey: publicKeyOfOtherParty,
			signature: signature
		)

		return signature.isValid(password.messageHash)
	}
}
