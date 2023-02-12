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

extension View {
	@ViewBuilder public func textStyle(_ style: TextStyle) -> some View {
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

extension TextStyle {
	fileprivate struct SheetTitle: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.sheetTitle)
				.lineSpacing(.lineSpacing(.𝟛𝟞))
		}
	}

	fileprivate struct SectionHeader: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.sectionHeader)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct SecondaryHeader: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.secondaryHeader)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body1Header: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Header)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body1HighImportance: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1HighImportance)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body1Regular: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Regular)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body1StandaloneLink: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1StandaloneLink)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body1Link: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body1Link)
				.lineSpacing(.lineSpacing(.𝟚𝟛))
		}
	}

	fileprivate struct Body2Header: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Header)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	fileprivate struct Body2HighImportance: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2HighImportance)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	fileprivate struct Body2Regular: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Regular)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	fileprivate struct Body2Link: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.body2Link)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}

	fileprivate struct Button: ViewModifier {
		func body(content: Content) -> some View {
			content
				.font(.app.button)
				.lineSpacing(.lineSpacing(.𝟙𝟠))
		}
	}
}

extension CGFloat {
	fileprivate static func lineSpacing(_ value: LineSpacing) -> CGFloat {
		value.rawValue / 4
	}
}

// MARK: - CGFloat.LineSpacing
extension CGFloat {
	fileprivate enum LineSpacing: CGFloat {
		case 𝟛𝟞 = 36
		case 𝟚𝟛 = 23
		case 𝟙𝟠 = 18
	}
}
