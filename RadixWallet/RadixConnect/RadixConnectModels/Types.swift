import WebRTC

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

extension ConnectionPassword {
	var messageToHash: Data {
		let prefix = Data("L".utf8)
		let passwordData = self.data.data
		var messageData = Data()
		messageData.append(prefix)
		messageData.append(passwordData)

		return Data(messageData)
	}
}

#if DEBUG
extension ConnectionPassword {
	public static let placeholder = try! Self(.init(.deadbeef32Bytes))
}
#endif // DEBUG

// MARK: - CEPublicKeyTag
public enum CEPublicKeyTag {}
public typealias CEPublicKey = Tagged<CEPublicKeyTag, HexCodable32Bytes>

#if DEBUG
extension CEPublicKey {
	public static let placeholder = try! Self(.init(.deadbeef32Bytes))
}
#endif // DEBUG

// MARK: - CESignatureTag
public enum CESignatureTag {}
public typealias CESignature = Tagged<CESignatureTag, HexCodable>

#if DEBUG
extension CESignature {
	public static let placeholder = try! Self(.deadbeef32Bytes)
}
#endif // DEBUG

// MARK: - LinkConnectionQRData
public struct LinkConnectionQRData: Sendable, Hashable, Decodable {
	public let purpose: ConnectionPurpose
	public let password: ConnectionPassword
	public let publicKey: CEPublicKey
	public let signature: CESignature
}

extension LinkConnectionQRData {
	public func hasValidSignature() throws -> Bool {
		let signature = try SignatureWithPublicKey.eddsaEd25519(
			signature: signature.data,
			publicKey: .init(rawRepresentation: publicKey.data.data)
		)

		return signature.isValidSignature(for: password.messageToHash.hash().data)
	}
}

#if DEBUG
extension LinkConnectionQRData {
	public static let placeholder = try! Self(
		purpose: .general,
		password: .placeholder,
		publicKey: .placeholder,
		signature: .placeholder
	)
}
#endif // DEBUG

// MARK: - ConnectionPurpose
public enum ConnectionPurpose: String, Sendable, Codable, UnknownCaseDecodable {
	case general
	case unknown
}
