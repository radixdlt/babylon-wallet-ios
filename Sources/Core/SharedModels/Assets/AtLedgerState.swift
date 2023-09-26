public struct AtLedgerState: Hashable, Codable, Sendable {
	public let version: Int64
	public let epoch: Int64

	public init(version: Int64, epoch: Int64) {
		self.version = version
		self.epoch = epoch
	}
}
