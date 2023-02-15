import SwiftUI

// MARK: - TextStyle
public enum TextStyle {
	case sheetTitle
	case sectionHeader
	case secondaryHeader
	case body1Header
	case body1HighImportance
	case body1Regular
	case body1StandaloneLink
	case body1Link
	case body2Header
	case body2HighImportance
	case body2Regular
	case body2Link
	case button
}

public extension View {
	func textStyle(_ style: TextStyle) -> some View {
		font(style.font)
			.lineSpacing(style.lineSpacing)
	}
}

extension TextStyle {
	var font: Font {
		switch self {
		case .sheetTitle: return .app.sheetTitle
		case .sectionHeader: return .app.sectionHeader
		case .secondaryHeader: return .app.secondaryHeader
		case .body1Header: return .app.body1Header
		case .body1HighImportance: return .app.body1HighImportance
		case .body1Regular: return .app.body1Regular
		case .body1StandaloneLink: return .app.body1StandaloneLink
		case .body1Link: return .app.body1Link
		case .body2Header: return .app.body2Header
		case .body2HighImportance: return .app.body2HighImportance
		case .body2Regular: return .app.body2Regular
		case .body2Link: return .app.body2Link
		case .button: return .app.button
		}
	}

	var lineSpacing: CGFloat {
		switch self {
		case .sheetTitle:
			return 36 / 4

		case .sectionHeader,
		     .secondaryHeader,
		     .body1Header,
		     .body1HighImportance,
		     .body1Regular,
		     .body1StandaloneLink,
		     .body1Link:
			return 23 / 4

		case .body2Header,
		     .body2HighImportance,
		     .body2Regular,
		     .body2Link,
		     .button:
			return 18 / 4
		}
	}
}

// MARK: - TextType
public enum TextType {
	/// Text formatted as a section heading
	case sectionHeading

	/// Text formatted as an info item
	case infoItem

	/// Text formatted as an info item
	case textBlock
}

public extension View {
	func textType(_ type: TextType) -> some View {
		let styling = type.textStyling
		return textStyle(styling.textStyle)
			.foregroundColor(styling.color)
	}

	var flushedLeft: some View {
		HStack(spacing: 0) {
			self
			Spacer(minLength: 0)
		}
	}
}

extension TextType {
	var textStyling: (textStyle: TextStyle, color: Color) {
		switch self {
		case .sectionHeading:
			return (.body1Regular, .app.gray2)

		case .infoItem:
			return (.body1HighImportance, .app.gray1)

		case .textBlock:
			return (.body1HighImportance, .app.gray2)
		}
	}
}
