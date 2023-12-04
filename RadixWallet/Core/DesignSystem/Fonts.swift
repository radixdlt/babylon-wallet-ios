
extension SwiftUI.Font {
	/// Namespace only
	public struct App { fileprivate init() {} }
	public static let app = App()
}

extension SwiftUI.Font.App {
	public var sheetTitle: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 32)
	}

	public var sectionHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 20)
	}

	public var secondaryHeader: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 18)
	}

	public var resourceLabel: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 11)
	}

	public var backButton: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 18)
	}

	public var body1Header: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.semiBold, size: 16)
	}

	public var body1HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 16)
	}

	public var body1Regular: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.regular, size: 16)
	}

	public var body1StandaloneLink: SwiftUI.Font {
		body1Header
	}

	public var body1Link: SwiftUI.Font {
		body1HighImportance
	}

	public var body2Header: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 14)
	}

	public var body2HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 14)
	}

	public var body2Regular: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.regular, size: 14)
	}

	public var body2Link: SwiftUI.Font {
		body2Header
	}

	public var body3HighImportance: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.medium, size: 12)
	}

	public var button: SwiftUI.Font {
		.custom(FontFamily.IBMPlexSans.bold, size: 16)
	}

	public var monospace: SwiftUI.Font {
		.system(size: 13, design: .monospaced)
	}
}

/// UIFont/NSFont depending on platform.
extension FontConvertible.Font {
	/// Namespace only
	public struct App { fileprivate init() {} }
	public static let app = App()
}

extension FontConvertible.Font.App {
	public var sheetTitle: FontConvertible.Font {
		FontFamily.IBMPlexSans.bold.font(size: 32)
	}

	public var secondaryHeader: FontConvertible.Font {
		FontFamily.IBMPlexSans.semiBold.font(size: 18)
	}

	public var backButton: FontConvertible.Font {
		FontFamily.IBMPlexSans.medium.font(size: 18)
	}
}
