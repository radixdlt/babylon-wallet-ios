import CryptoKit
import Foundation

// MARK: - ConnectionSecrets
public struct ConnectionSecrets: Sendable, Hashable {
	public let connectionPassword: ConnectionPassword
	public let connectionID: P2PConnectionID
	public let encryptionKey: EncryptionKey

	public init(
		connectionPassword: ConnectionPassword,
		connectionID: P2PConnectionID,
		encryptionKey: EncryptionKey
	) {
		self.connectionPassword = connectionPassword
		self.connectionID = connectionID
		self.encryptionKey = encryptionKey
	}
}

extension ConnectionSecrets {
	public static func from(connectionPassword: ConnectionPassword) throws -> Self {
		let connectionID = try P2PConnectionID(password: connectionPassword)

		return try Self(
			connectionPassword: connectionPassword,
			connectionID: connectionID,
			encryptionKey: .init(data: connectionPassword.data.data)
		)
	}
}

extension P2PConnectionID {
	public init(password connectionPassword: ConnectionPassword) throws {
		let connectionIDData = Data(SHA256.hash(data: connectionPassword.data.data))

		try self.init(data: connectionIDData)
	}
}

#if DEBUG
extension ConnectionSecrets {
	public static let placeholder = Self(
		connectionPassword: .placeholder,
		connectionID: .placeholder,
		encryptionKey: try! .init(data: .deadbeef32Bytes)
	)

	public static func random() throws -> Self {
		try .from(connectionPassword: .random())
	}
}
#endif // DEBUG
