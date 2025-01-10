extension SharedKey where Self == InMemoryKey<SecurityShieldBuilder>.Default {
	static var shieldBuilder: Self {
		Self[.inMemory("shieldBuilder"), default: SecurityShieldBuilder()]
	}
}

extension Shared where Value == SecurityShieldBuilder {
	func initialize() {
		withLock { sharedValue in
			sharedValue = SecurityShieldBuilder()
		}
	}
}

// MARK: - SecurityShieldBuilder + @unchecked Sendable
extension SecurityShieldBuilder: @unchecked Sendable {}

// MARK: - Shared + Hashable
extension Shared: Hashable where Value: Hashable {
	public static func == (lhs: Shared<Value>, rhs: Shared<Value>) -> Bool {
		lhs.wrappedValue == rhs.wrappedValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.wrappedValue)
	}
}

// MARK: - SharedReader + Hashable
extension SharedReader: Hashable where Value: Hashable {
	public static func == (lhs: SharedReader<Value>, rhs: SharedReader<Value>) -> Bool {
		lhs.wrappedValue == rhs.wrappedValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.wrappedValue)
	}
}
