import Foundation

// MARK: - TransactionIntent
public struct TransactionIntent: Sendable, Codable, Hashable {
	public let header: TransactionHeader
	public let manifest: TransactionManifest

	public init(header: TransactionHeader, manifest: TransactionManifest) {
		self.header = header
		self.manifest = manifest
	}
}

public extension TransactionIntent {
	func accountsRequiredToSign() throws -> Set<ComponentAddress> {
		try manifest.accountsRequiredToSign(
			networkId: header.networkId,
			version: header.version
		)
	}
}
