import SwiftUI

/// A leading adjusted block of text, with the given formatting
public struct TextBlock: View {
	let text: String
	let textStyle: TextStyle
	let color: Color

	/// A leading adjusted text, formatted as a section heading
	public init(sectionHeading text: String) {
		self.init(text, textStyle: .body1Regular, color: .app.gray2)
	}

	public init(_ text: String, textStyle: TextStyle = .body1Regular, color: Color = .app.gray1) {
		self.text = text
		self.textStyle = textStyle
		self.color = color
	}

	public var body: some View {
		HStack(spacing: 0) {
			Text(text)
				.textStyle(textStyle)
				.foregroundColor(color)
			Spacer(minLength: 0)
		}
	}
}
