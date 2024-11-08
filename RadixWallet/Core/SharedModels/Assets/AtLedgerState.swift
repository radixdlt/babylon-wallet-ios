struct AtLedgerState: Hashable, Codable, Sendable {
	let version: Int64
	let epoch: Int64

	init(version: Int64, epoch: Int64) {
		self.version = version
		self.epoch = epoch
	}
}
