public struct DecodeAddressRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let address: String

	// MARK: Init

	public init(address: String) {
		self.address = address
	}
}
