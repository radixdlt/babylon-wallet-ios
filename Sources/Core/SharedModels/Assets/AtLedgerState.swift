public struct AtLedgerState: Hashable, Codable {
	public let version: Int64

	public init(version: Int64) {
		self.version = version
	}
}
