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
	@ViewBuilder func textStyle(_ style: TextStyle) -> some View {
		switch style {
		case .sheetTitle:
			modifier(TextStyle.SheetTitle())
		case .sectionHeader:
			modifier(TextStyle.SectionHeader())
		case .secondaryHeader:
			modifier(TextStyle.SecondaryHeader())
		case .body1Header:
			modifier(TextStyle.Body1Header())
		case .body1HighImportance:
			modifier(TextStyle.Body1HighImportance())
		case .body1Regular:
			modifier(TextStyle.Body1Regular())
		case .body1StandaloneLink:
			modifier(TextStyle.Body1StandaloneLink())
		case .body1Link:
			modifier(TextStyle.Body1Link())
		case .body2Header:
			modifier(TextStyle.Body2Header())
		case .body2HighImportance:
			modifier(TextStyle.Body2HighImportance())
		case .body2Regular:
			modifier(TextStyle.Body2Regular())
		case .body2Link:
			modifier(TextStyle.Body2Link())
		case .button:
			modifier(TextStyle.Button())
		}
	}
}

private extension TextStyle {
	struct SheetTitle: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.sheetTitle)
				.lineSpacing(.lineSpacing(.𝟛𝟞))
		}
	}

	struct SectionHeader: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.sectionHeader)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct SecondaryHeader: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.secondaryHeader)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body1Header: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Header)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body1HighImportance: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1HighImportance)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body1Regular: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Regular)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body1StandaloneLink: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1StandaloneLink)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body1Link: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Link)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	struct Body2Header: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Header)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	struct Body2HighImportance: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2HighImportance)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	struct Body2Regular: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Regular)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	struct Body2Link: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Link)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	struct Button: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.button)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}
}

// MARK: - TextStyle_
//public struct TextStyle_ {
//	let font: Font
//	let lineSpacing: CGFloat
//		
//	public static let sheetTitle = TextStyle_(font: .app.sheetTitle, lineSpacing: .𝟛𝟞)
//	public static let sectionHeader = TextStyle_(font: .app.sectionHeader, lineSpacing: .𝟚𝟛)
//	public static let secondaryHeader = TextStyle_(font: .app.secondaryHeader, lineSpacing: .𝟚𝟛)
//	public static let body1Header = TextStyle_(font: .app.body1Header, lineSpacing: .𝟚𝟛)
//	public static let body1HighImportance = TextStyle_(font: .app.body1HighImportance, lineSpacing: .𝟚𝟛)
//	public static let body1Regular = TextStyle_(font: .app.body1Regular, lineSpacing: .𝟚𝟛)
//	public static let body1StandaloneLink = TextStyle_(font: .app.body1StandaloneLink, lineSpacing: .𝟚𝟛)
//	public static let body1Link = TextStyle_(font: .app.body1Link, lineSpacing: .𝟚𝟛)
//	public static let body2Header = TextStyle_(font: .app.body2Header, lineSpacing: .𝟙𝟠)
//	public static let body2HighImportance = TextStyle_(font: .app.body2HighImportance, lineSpacing: .𝟙𝟠)
//	public static let body2Regular = TextStyle_(font: .app.body2Regular, lineSpacing: .𝟙𝟠)
//	public static let body2Link = TextStyle_(font: .app.body2Link, lineSpacing: .𝟙𝟠)
//	public static let button = TextStyle_(font: .app.button, lineSpacing: .𝟙𝟠)
//}
//
//public extension View {
//	func textStyle(_ style: TextStyle_) -> some View {
//		self.font(style.font)
//			.lineSpacing(style.lineSpacing)
//	}
//}
//
//private extension TextStyle_ {
//	init(font: Font, lineSpacing: CGFloat.LineSpacing) {
//		self.font = font
//		self.lineSpacing = .lineSpacing(lineSpacing)
//	}
//}

private extension CGFloat {
	static func lineSpacing(_ value: LineSpacing) -> CGFloat {
		value.rawValue / 4
	}
}

// MARK: - CGFloat.LineSpacing
private extension CGFloat {
	enum LineSpacing: CGFloat {
		case 𝟛𝟞 = 36
		case 𝟚𝟛 = 23
		case 𝟙𝟠 = 18
	}
}
