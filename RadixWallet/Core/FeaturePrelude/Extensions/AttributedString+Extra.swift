extension Text {
	/// Shows a markdown string, where any italics sections are shown in the provided color
	public init(markdown: String, emphasizedColor: Color) {
		let attributed = AttributedString(markdown: markdown, replaceEmphasizedWith: emphasizedColor)
		self.init(attributed)
	}
}

extension AttributedString {
	public init(_ string: some StringProtocol, foregroundColor: Color) {
		self = update(AttributedString(string)) { $0.foregroundColor = foregroundColor }
	}

	public init(markdown: some StringProtocol, replaceEmphasizedWith emphasizedColor: Color) {
		let string = String(markdown)
		guard let attributed = try? AttributedString(markdown: string) else {
			self.init(string)
			return
		}

		let replacement = AttributeContainer.foregroundColor(emphasizedColor)
		self = attributed
			.replacingAttributes(.emphasized, with: replacement)
			.replacingAttributes(.stronglyEmphasized, with: replacement)
	}
}

extension AttributeContainer {
	public static let emphasized: AttributeContainer = intent(.emphasized)
	public static let stronglyEmphasized: AttributeContainer = intent(.stronglyEmphasized)

	public static func intent(_ intent: InlinePresentationIntent) -> AttributeContainer {
		var result = AttributeContainer()
		result.inlinePresentationIntent = intent
		return result
	}

	public static func foregroundColor(_ color: Color) -> AttributeContainer {
		var result = AttributeContainer()
		result.foregroundColor = color
		return result
	}
}
