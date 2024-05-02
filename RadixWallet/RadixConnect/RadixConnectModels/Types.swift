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
		let passwordData = self.hash().data
		var messageData = Data()
		messageData.append(prefix)
		messageData.append(passwordData)

		return Data(messageData)
	}
}

// MARK: - Curve25519PublicKeyBytesTag
public enum Curve25519PublicKeyBytesTag {}
public typealias Curve25519PublicKeyBytes = Tagged<Curve25519PublicKeyBytesTag, Exactly32Bytes>

#if DEBUG
extension Curve25519PublicKeyBytes {
	public static let sample = try! Self(.init(.deadbeef32Bytes))
}
#endif // DEBUG

// MARK: - CESignatureTag
public enum CESignatureTag {}
public typealias CESignature = Tagged<CESignatureTag, HexCodable>

#if DEBUG
extension CESignature {
	public static let sample = Self(.deadbeef32Bytes)
}
#endif // DEBUG

// MARK: - LinkConnectionQRData
public struct LinkConnectionQRData: Sendable, Hashable, Decodable {
	public let purpose: ConnectionPurpose
	public let password: RadixConnectPassword
	public let publicKey: Curve25519PublicKeyBytes

	/// Represents a signature produced by CE by signing the hash of the `password`
	/// with the private key of the `publicKey`.
	///
	/// The same logic to compute the message to be signed is used by both, wallet and CE.
	/// (see `RadixConnectPassword.messageToHash`)
	public let signature: CESignature
}

extension LinkConnectionQRData {
	public func hasValidSignature() throws -> Bool {
		false

		// FIXME: -
//		let signature = try SignatureWithPublicKey.eddsaEd25519(
//			signature: signature.data,
//			publicKey: .init(rawRepresentation: publicKey.data.data)
//		)
//
//		return signature.isValidSignature(for: password.messageToHash.hash().data)
	}
}

#if DEBUG
extension LinkConnectionQRData {
	public static let sample = Self(
		purpose: .general,
		password: .sample,
		publicKey: .sample,
		signature: .sample
	)
}
#endif // DEBUG

// MARK: - ConnectionPurpose
public enum ConnectionPurpose: String, Sendable, Codable, UnknownCaseDecodable {
	case general
	case unknown
}

// import WebRTC
//
//// MARK: - P2PLink
///// A client the user have connected P2P with, typically a
///// WebRTC connections with a DApp, but might be Android or iPhone
///// client as well.
// public struct P2PLink:
//    Sendable,
//    Hashable,
//    Codable,
//    Identifiable
// {
//    public var id: Curve25519PublicKeyBytes {
//        publicKey
//    }
//
//    /// The `RadixConnectPassword` is used to be able to restablish the P2P connection.
//    public let connectionPassword: RadixConnectPassword
//
//    /// Acts as the seed for the `ID`.
//    public let publicKey: Curve25519PublicKeyBytes
//
//    /// Link purpose
//    public let purpose: ConnectionPurpose
//
//    /// Client name, e.g. "Chrome on Macbook" or "My work Android" or "My wifes iPhone SE".
//    public let displayName: String
//
//    /// The canonical initializer requiring a `RadixConnectPassword`, `Curve25519PublicKeyBytes`, `ConnectionPurpose` and `Display` name.
//    public init(
//        connectionPassword: RadixConnectPassword,
//        publicKey: Curve25519PublicKeyBytes,
//        purpose: ConnectionPurpose,
//        displayName: String
//    ) {
//        self.connectionPassword = connectionPassword
//        self.publicKey = publicKey
//        self.purpose = purpose
//        self.displayName = displayName
//    }
// }
//
//// MARK: Equatable
// extension P2PLink: Equatable {
//    public static func == (lhs: Self, rhs: Self) -> Bool {
//        lhs.id == rhs.id
//    }
// }
