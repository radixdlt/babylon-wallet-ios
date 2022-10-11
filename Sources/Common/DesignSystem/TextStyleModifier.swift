import SwiftUI

// MARK: - Style
public enum Style {
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
	@ViewBuilder func textStyle(_ style: Style) -> some View {
		switch style {
		case .sheetTitle:
			modifier(Style.SheetTitle())
		case .sectionHeader:
			modifier(Style.SectionHeader())
		case .secondaryHeader:
			modifier(Style.SecondaryHeader())
		case .body1Header:
			modifier(Style.Body1Header())
		case .body1HighImportance:
			modifier(Style.Body1HighImportance())
		case .body1Regular:
			modifier(Style.Body1Regular())
		case .body1StandaloneLink:
			modifier(Style.Body1StandaloneLink())
		case .body1Link:
			modifier(Style.Body1Link())
		case .body2Header:
			modifier(Style.Body2Header())
		case .body2HighImportance:
			modifier(Style.Body2HighImportance())
		case .body2Regular:
			modifier(Style.Body2Regular())
		case .body2Link:
			modifier(Style.Body2Link())
		case .button:
			modifier(Style.Button())
		}
	}
}

private extension Style {
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

private extension CGFloat {
	static func lineSpacing(_ value: LineSpacing) -> CGFloat {
		value.rawValue / 3
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
