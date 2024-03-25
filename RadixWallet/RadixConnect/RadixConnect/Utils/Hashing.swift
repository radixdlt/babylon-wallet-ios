import WebRTC

extension ConnectionPassword {
	func hash() throws -> Data {
		try self.data.data.hash()
	}
}
