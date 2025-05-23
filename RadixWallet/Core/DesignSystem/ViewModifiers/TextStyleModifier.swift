import SwiftUI

// MARK: - TextStyle
enum TextStyle {
	case enlarged
	case sheetTitle
	case sectionHeader
	case secondaryHeader
	case resourceLabel
	case body1Header
	case body1HighImportance
	case body1Regular
	case body1StandaloneLink
	case body1Link
	case body2Header
	case body2HighImportance
	case body2Regular
	case body2Link
	case body3HighImportance
	case body3Regular
	case button
	case monospace
}

extension TextStyle {
	var font: SwiftUI.Font {
		switch self {
		case .enlarged: .app.enlarged
		case .sheetTitle: .app.sheetTitle
		case .sectionHeader: .app.sectionHeader
		case .secondaryHeader: .app.secondaryHeader
		case .resourceLabel: .app.resourceLabel
		case .body1Header: .app.body1Header
		case .body1HighImportance: .app.body1HighImportance
		case .body1Regular: .app.body1Regular
		case .body1StandaloneLink: .app.body1StandaloneLink
		case .body1Link: .app.body1Link
		case .body2Header: .app.body2Header
		case .body2HighImportance: .app.body2HighImportance
		case .body2Regular: .app.body2Regular
		case .body2Link: .app.body2Link
		case .body3HighImportance: .app.body3HighImportance
		case .body3Regular: .app.body3Regular
		case .button: .app.button
		case .monospace: .app.monospace
		}
	}

	var lineSpacing: CGFloat {
		switch self {
		case .sheetTitle, .resourceLabel:
			0
		case .enlarged:
			2
		case .sectionHeader, .secondaryHeader, .body1Header,
		     .body1HighImportance, .body1Regular, .body1StandaloneLink, .body1Link:
			23 / 4
		case .body2Header, .body2HighImportance, .body2Regular,
		     .body2Link, .body3HighImportance, .body3Regular, .button, .monospace:
			18 / 4
		}
	}
}

extension View {
	func textStyle(_ style: TextStyle) -> some View {
		font(style.font)
			.lineSpacing(style.lineSpacing)
	}
}

extension Text {
	/// Text formatted as a section heading
	var sectionHeading: some View {
		textStyle(.body1Header)
			.foregroundColor(.secondaryText)
	}

	/// Text formatted as an info item
	var infoItem: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.primaryText)
	}

	/// An informative block of text
	var textBlock: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.secondaryText)
	}

	/// A url
	var urlLink: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.textButton)
	}
}

extension View {
	var flushedLeft: some View {
		flushedLeft(padding: 0)
	}

	func flushedLeft(padding: CGFloat) -> some View {
		frame(maxWidth: .infinity, alignment: .leading)
			.padding(.leading, padding)
	}

	var flushedRight: some View {
		frame(maxWidth: .infinity, alignment: .trailing)
	}

	var centered: some View {
		frame(maxWidth: .infinity, alignment: .center)
	}
}
