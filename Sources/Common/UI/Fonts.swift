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

extension Font {
	enum Size: CGFloat {
		case 𝟙𝟙 = 11
		case 𝟙𝟜 = 14
		case 𝟙𝟞 = 16
		case 𝟚𝟞 = 26
		case 𝟜𝟞 = 46
	}
}

public extension Font.App {
	var caption: Font {
		.custom(.𝟙𝟙, .bold)
	}

	var subhead: Font {
		.custom(.𝟙𝟜, .semibold)
	}

	var body: Font {
		.custom(.𝟙𝟞, .regular)
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
