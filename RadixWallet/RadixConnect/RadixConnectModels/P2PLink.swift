import WebRTC

// MARK: - P2PLink
/// A client the user have connected P2P with, typically a
/// WebRTC connections with a DApp, but might be Android or iPhone
/// client as well.
public struct P2PLink:
	Sendable,
	Hashable,
	Codable,
	Identifiable
{
	public var id: ConnectionPublicKey {
		publicKey
	}

	/// The most important property of this struct, the `ConnectionPassword`,
	/// is used to be able to restablish the P2P connection and also acts as the seed
	/// for the `ID`.
	public let connectionPassword: ConnectionPassword

	public let publicKey: ConnectionPublicKey

	public let purpose: ConnectionPurpose

	/// Client name, e.g. "Chrome on Macbook" or "My work Android" or "My wifes iPhone SE".
	public let displayName: String

	/// The canonical initializer requiring a `ConnectionPassword` and `Display` name.
	public init(
		connectionPassword: ConnectionPassword,
		publicKey: ConnectionPublicKey,
		purpose: ConnectionPurpose,
		displayName: String
	) {
		self.connectionPassword = connectionPassword
		self.publicKey = publicKey
		self.purpose = purpose
		self.displayName = displayName
	}
}

// MARK: Equatable
extension P2PLink: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
}
