extension SharedKey where Self == InMemoryKey<MnemonicBuilder>.Default {
	static var mnemonicBuilder: Self {
		Self[.inMemory("mnemonicBuilder"), default: MnemonicBuilder()]
	}
}

extension Shared where Value == MnemonicBuilder {
	func initialize() {
		withLock { sharedValue in
			sharedValue = MnemonicBuilder()
		}
	}
}

// MARK: - mnemonicBuilder + @unchecked Sendable
extension MnemonicBuilder: @unchecked Sendable {}
