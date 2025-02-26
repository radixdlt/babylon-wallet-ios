extension SharedKey where Self == InMemoryKey<DeviceMnemonicBuilder>.Default {
	static var deviceMnemonicBuilder: Self {
		Self[.inMemory("deviceMnemonicBuilder"), default: DeviceMnemonicBuilder()]
	}
}

extension Shared where Value == DeviceMnemonicBuilder {
	func initialize() {
		withLock { sharedValue in
			sharedValue = DeviceMnemonicBuilder()
		}
	}
}

// MARK: - DeviceMnemonicBuilder + @unchecked Sendable
extension DeviceMnemonicBuilder: @unchecked Sendable {}
