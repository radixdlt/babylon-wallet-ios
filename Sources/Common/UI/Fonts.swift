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
		.system(size: size.rawValue,
		        weight: weight)
	}
}

// MARK: - Font.Size
extension Font {
	enum Size: CGFloat {
		case 𝟙𝟘 = 10
		case 𝟙𝟙 = 11
		case 𝟙𝟜 = 14
		case 𝟙𝟠 = 18
		case 𝟙𝟞 = 16
		case 𝟚𝟜 = 24
		case 𝟚𝟞 = 26
		case 𝟜𝟞 = 46
	}
}

public extension Font.App {
	var footnote: Font {
		.custom(.𝟙𝟘, .semibold)
	}

	var caption1: Font {
		.custom(.𝟙𝟙, .bold)
	}

	var caption2: Font {
		.custom(.𝟙𝟜, .regular)
	}

	var subhead: Font {
		.custom(.𝟙𝟜, .semibold)
	}

	var body: Font {
		.custom(.𝟙𝟞, .regular)
	}

	var buttonBody: Font {
		.custom(.𝟙𝟞, .semibold)
	}

	var textFieldRegular: Font {
		.custom(.𝟙𝟠, .regular)
	}

	var buttonTitle: Font {
		.custom(.𝟙𝟠, .semibold)
	}

	var title2Bold: Font {
		.custom(.𝟚𝟜, .bold)
	}

	var title: Font {
		.custom(.𝟚𝟞, .semibold)
	}

	var titleBold: Font {
		.custom(.𝟚𝟞, .bold)
	}

	var largeTitle: Font {
		.custom(.𝟜𝟞, .bold)
	}
}
