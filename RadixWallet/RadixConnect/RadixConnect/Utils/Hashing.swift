import Sargon

extension RadixConnectPassword {
	func hash() -> Hash {
		self.value.hash()
	}
}
