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
