
extension AppearanceID {
	var gradient: LinearGradient {
		.init(self)
	}
}

extension LinearGradient {
	init(_ accountAppearanceID: AppearanceID) {
		self.init(gradient: .init(accountAppearanceID), startPoint: .leading, endPoint: .trailing)
	}
}

extension Gradient {
	init(_ accountAppearanceID: AppearanceID) {
		self.init(accountNumber: accountAppearanceID.value)
	}
}
