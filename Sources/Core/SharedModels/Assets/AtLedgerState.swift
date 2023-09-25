public struct AtLedgerState: Hashable, Codable, Sendable {
	public let version: Int64

	public init(version: Int64) {
		self.version = version
	}
}
