
extension SwiftUI.Font {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

extension SwiftUI.Font.App {
	var enlarged: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 50)
	}

	var sheetTitle: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 32)
	}

	var sectionHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 20)
	}

	var secondaryHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 18)
	}

	var resourceLabel: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 11)
	}

	var backButton: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 18)
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

	var body3HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 12)
	}

	var body3Regular: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.regular, size: 12)
	}

	var button: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 16)
	}

	var monospace: SwiftUI.Font {
		.system(size: 13, design: .monospaced)
	}
}

/// UIFont/NSFont depending on platform.
extension FontConvertible.Font {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

extension UIFont {
	static var body1Regular: UIFont {
		UIFont(font: FontFamily.IBMPlexSans.regular, size: 16)!
	}
}
