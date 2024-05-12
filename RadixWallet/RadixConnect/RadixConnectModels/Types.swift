import WebRTC

// MARK: - PeerConnectionIdTag
/// The Established Peer Connection ID.
public enum PeerConnectionIdTag {}
public typealias PeerConnectionID = Tagged<PeerConnectionIdTag, String>

// MARK: Sendable
extension PeerConnectionID: Sendable {}

// TODO: move to Sargon
extension RadixConnectPassword {
	/// Represents the message to be signed and sent to CE.
	/// CE uses the same logic to compute its own message.
	var messageToHash: Data {
		let prefix = Data("L".utf8)
		let passwordData = self.value.data
		var messageData = Data()
		messageData.append(prefix)
		messageData.append(passwordData)

		return Data(messageData)
	}
}

extension LinkConnectionQRData {
	public func hasValidSignature() -> Bool {
		let signature = SignatureWithPublicKey.ed25519(
			publicKey: publicKeyOfOtherParty,
			signature: signature
		)

		return signature.isValid(password.messageToHash.hash())
	}
}
