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
	case monospace
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
		case .monospace: return .app.monospace
		}
	}

	var lineSpacing: CGFloat {
		switch self {
		case .sheetTitle:
			return 36 / 4
		case .sectionHeader, .secondaryHeader, .body1Header,
		     .body1HighImportance, .body1Regular, .body1StandaloneLink, .body1Link:
			return 23 / 4
		case .body2Header, .body2HighImportance, .body2Regular,
		     .body2Link, .button, .monospace:
			return 18 / 4
		}
	}
}

extension View {
	public func textStyle(_ style: TextStyle) -> some View {
		font(style.font)
			.lineSpacing(style.lineSpacing)
	}
}

extension Text {
	/// Text formatted as a section heading
	public var sectionHeading: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray2)
	}

	/// Text formatted as an info item
	public var infoItem: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.app.gray1)
	}

	/// An informative block of text
	public var textBlock: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.app.gray2)
	}

	/// A url
	public var urlLink: some View {
		textStyle(.body1HighImportance)
			.foregroundColor(.app.blue2)
	}
}

extension View {
	public var flushedLeft: some View {
		flushedLeft(padding: 0)
	}

	public func flushedLeft(padding: CGFloat) -> some View {
		HStack(spacing: 0) {
			self
			Spacer(minLength: 0)
		}
		.padding(.leading, padding)
	}

	public var flushedRight: some View {
		HStack(spacing: 0) {
			Spacer(minLength: 0)
			self
		}
	}
}
