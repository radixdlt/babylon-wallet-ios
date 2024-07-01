extension Text {
	@_disfavoredOverload
	init?(_ content: (some StringProtocol)?) {
		guard let content else {
			return nil
		}
		self.init(content)
	}
}
