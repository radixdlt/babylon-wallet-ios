import Resources
import SwiftUI

public extension SwiftUI.Font {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

public extension SwiftUI.Font.App {
	var sheetTitle: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 32)
	}

	var sectionHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 20)
	}

	var secondaryHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 18)
	}

	var body1Header: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 16)
	}

	var body1HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 16)
	}

	var body1Regular: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.regular, size: 16)
	}

	var body1StandaloneLink: SwiftUI.Font {
		body1Header
	}

	var body1Link: SwiftUI.Font {
		body1HighImportance
	}

	var body2Header: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 14)
	}

	var body2HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 14)
	}

	var body2Regular: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.regular, size: 14)
	}

	var body2Link: SwiftUI.Font {
		body2Header
	}

	var button: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 16)
	}
}
