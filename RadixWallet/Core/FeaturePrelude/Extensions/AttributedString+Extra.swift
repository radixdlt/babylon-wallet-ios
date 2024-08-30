extension Text {
	/// Shows a markdown string, where any italics/bold sections are shown in the provided color and font.
	public init(markdown: String, emphasizedColor: Color, emphasizedFont: SwiftUI.Font? = nil) {
		let attributed = AttributedString(markdown: markdown, replaceEmphasizedWith: emphasizedColor, font: emphasizedFont)
		self.init(attributed)
	}
}

extension AttributedString {
	public init(_ string: some StringProtocol, foregroundColor: Color) {
		self = update(AttributedString(string)) { $0.foregroundColor = foregroundColor }
	}

	public init(markdown: some StringProtocol, replaceEmphasizedWith color: Color, font: SwiftUI.Font?) {
		let string = String(markdown)
		guard let attributed = try? AttributedString(markdown: string) else {
			self.init(string)
			return
		}

		let replacement = AttributeContainer.emphasized(color: color, font: font)
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

	public static func emphasized(color: Color, font: SwiftUI.Font?) -> AttributeContainer {
		var result = AttributeContainer()
		result.font = font
		result.foregroundColor = color
		return result
	}
}
