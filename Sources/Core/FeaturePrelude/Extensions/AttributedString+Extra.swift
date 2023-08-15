import Prelude
import SwiftUI

extension Text {
	/// Shows a markdown string, where any italics sections are shown in the provided color
	public init(markdown: String, italicsColor: Color) {
		let attributed = AttributedString(markdown: markdown, replaceItalicsWith: italicsColor)
		self.init(attributed)
	}
}

// TODO: replace usage with AttributedStringBuilder
// (@davdroman will work on one and open source it in his spare time)
extension AttributedString {
	public init(_ string: some StringProtocol, foregroundColor: Color) {
		self = update(AttributedString(string)) { $0.foregroundColor = foregroundColor }
	}

	public init(markdown: some StringProtocol, replaceItalicsWith italicsColor: Color) {
		let string = String(markdown)
		guard let attributed = try? AttributedString(markdown: string) else {
			self.init(string)
			return
		}

		self = attributed.replacingAttributes(.italics, with: .foregroundColor(italicsColor))
	}
}

extension AttributeContainer {
	public static let italics: AttributeContainer = intent(.emphasized)

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
