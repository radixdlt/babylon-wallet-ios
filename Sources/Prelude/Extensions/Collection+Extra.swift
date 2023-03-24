extension Collection {
	public var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

extension Optional where Wrapped: Collection {
	public var isNilOrEmpty: Bool {
		self == nil || self?.isEmpty == true
	}
}
