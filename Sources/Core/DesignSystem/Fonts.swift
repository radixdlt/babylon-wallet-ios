import SwiftUI

public extension Font {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

extension Font {
	static func custom(
		_ size: Size,
		_ weight: Font.Weight = .regular
	) -> Self {
		let fontName = IBMPlexSans.fontName(for: weight)
		return .custom(fontName, size: size.rawValue)
	}
}

// MARK: - Font.IBMPlexSans
extension Font {
	enum IBMPlexSans: String {
		case regular = "IBMPlexSans-Regular"
		case medium = "IBMPlexSans-Medium"
		case semiBold = "IBMPlexSans-SemiBold"
		case bold = "IBMPlexSans-Bold"

		static func fontName(for weight: Font.Weight) -> String {
			switch weight {
			case .regular:
				return IBMPlexSans.regular.rawValue
			case .medium:
				return IBMPlexSans.medium.rawValue
			case .semibold:
				return IBMPlexSans.semiBold.rawValue
			case .bold:
				return IBMPlexSans.bold.rawValue
			default:
				fatalError("Font weight not defined in design system")
			}
		}
	}
}

// MARK: - Font.Size
extension Font {
	enum Size: CGFloat {
		case 𝟙𝟜 = 14
		case 𝟙𝟞 = 16
		case 𝟙𝟠 = 18
		case 𝟚𝟘 = 20
		case 𝟛𝟚 = 32
	}
}

public extension Font.App {
	var sheetTitle: Font {
		.custom(.𝟛𝟚, .bold)
	}

	var sectionHeader: Font {
		.custom(.𝟚𝟘, .semibold)
	}

	var secondaryHeader: Font {
		.custom(.𝟙𝟠, .semibold)
	}

	var body1Header: Font {
		.custom(.𝟙𝟞, .semibold)
	}

	var body1HighImportance: Font {
		.custom(.𝟙𝟞, .medium)
	}

	var body1Regular: Font {
		.custom(.𝟙𝟞, .regular)
	}

	var body1StandaloneLink: Font {
		body1Header
	}

	var body1Link: Font {
		body1HighImportance
	}

	var body2Header: Font {
		.custom(.𝟙𝟜, .bold)
	}

	var body2HighImportance: Font {
		.custom(.𝟙𝟜, .medium)
	}

	var body2Regular: Font {
		.custom(.𝟙𝟜, .regular)
	}

	var body2Link: Font {
		body2Header
	}

	var button: Font {
		.custom(.𝟙𝟞, .bold)
	}
}
