
extension AppearanceID {
	public var gradient: LinearGradient {
		.init(self)
	}
}

extension LinearGradient {
	public init(_ accountAppearanceID: AppearanceID) {
		self.init(gradient: .init(accountAppearanceID), startPoint: .leading, endPoint: .trailing)
	}
}

extension Gradient {
	public init(_ accountAppearanceID: AppearanceID) {
		self.init(accountNumber: accountAppearanceID.value)
	}
}
