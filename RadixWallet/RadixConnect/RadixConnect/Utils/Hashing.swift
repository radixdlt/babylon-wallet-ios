import WebRTCimport WebRTCimport WebRTCimport WebRTC
extension Data {
	func hash() throws -> Data {
		try blake2b(data: self)
	}
}

extension ConnectionPassword {
	func hash() throws -> Data {
		try self.data.data.hash()
	}
}
