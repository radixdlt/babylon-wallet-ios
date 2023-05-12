import Prelude
import SwiftUI

// TODO: replace usage with AttributedStringBuilder
// (@davdroman will work on one and open source it in his spare time)
extension AttributedString {
	public init(_ string: some StringProtocol, foregroundColor: Color) {
		self = with(AttributedString(string)) { $0.foregroundColor = foregroundColor }
	}

	public init(markdown: some StringProtocol, emphasizedColor: Color) {
		let string = String(markdown)
		guard let attributed = try? AttributedString(markdown: string) else {
			self.init(string)
			return
		}

		self = attributed.replacingAttributes(.italic, with: .foregroundColor(emphasizedColor))
	}
}

extension AttributeContainer {
	static let italic: AttributeContainer = {
		var result = AttributeContainer()
		result.inlinePresentationIntent = .emphasized
		return result
	}()

	static let bold: AttributeContainer = {
		var result = AttributeContainer()
		result.inlinePresentationIntent = .stronglyEmphasized
		return result
	}()

	static func foregroundColor(_ color: Color) -> AttributeContainer {
		var result = AttributeContainer()
		result.foregroundColor = color
		return result
	}
}
