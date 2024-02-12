import WebRTC

extension Data {
	func hash() throws -> Data {
		Sargon.hash(data: self)
	}
}

extension ConnectionPassword {
	func hash() throws -> Data {
		try self.data.data.hash()
	}
}
