import WebRTC

extension ConnectionPassword {
	func hash() -> Data {
		self.data.data.hash().data
	}
}
