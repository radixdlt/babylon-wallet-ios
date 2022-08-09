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
		case 𝟙𝟞 = 16
		case 𝟚𝟞 = 26
	}
}

public extension Font.App {
	var title: Font {
		.custom(.𝟚𝟞, .semibold)
	}

	var body: Font {
		.custom(.𝟙𝟞, .regular)
	}

	var caption: Font {
		.custom(.𝟙𝟙, .bold)
	}
}
