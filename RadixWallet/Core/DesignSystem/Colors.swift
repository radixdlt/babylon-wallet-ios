
#if os(iOS)
typealias PlatformSpecificColor = UIColor
extension UIColor {
	static func dynamic(
		light lightModeColor: UIColor,
		dark darkModeColor: UIColor
	) -> UIColor {
		UIColor { $0.userInterfaceStyle == .dark ? darkModeColor : lightModeColor }
	}
}

#elseif os(macOS)
typealias PlatformSpecificColor = NSColor
extension NSColor {
	static func dynamic(
		light lightModeColor: NSColor,
		dark darkModeColor: NSColor
	) -> NSColor {
		NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? darkModeColor : lightModeColor })
	}
}
#endif

extension Color {
	#if os(iOS)
	static func dynamic(
		light lightModeColor: UIColor,
		dark darkModeColor: UIColor
	) -> Color {
		self.init(uiColor: .dynamic(light: lightModeColor, dark: darkModeColor))
	}

	#elseif os(macOS)
	static func dynamic(
		light lightModeColor: NSColor,
		dark darkModeColor: NSColor
	) -> Color {
		self.init(nsColor: .dynamic(light: lightModeColor, dark: darkModeColor))
	}
	#endif
}

extension Color {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

extension ShapeStyle where Self == Color {
	/// Namespace only
	static var app: Color.App { Color.app }
}

extension Color.App {
	// blue
	var blue1: Color { .init(hex: .blue1) }
	var blue2: Color { .init(hex: .blue2) }
	var blue3: Color { .init(hex: .blue3) }

	// green
	var green1: Color { .init(hex: .green1) }
	var green2: Color { .init(hex: .green2) }
	var green3: Color { .init(hex: .green3) }

	// gray
	var gray1: Color { .init(hex: .gray1) }
	var gray2: Color { .init(hex: .gray2) }
	var gray3: Color { .init(hex: .gray3) }
	var gray4: Color { .init(hex: .gray4) }
	var gray5: Color { .init(hex: .gray5) }

	// white
	var white: Color { .init(hex: .white) }
	/// white with 0.8 opacity
	var whiteTransparent: Color { .white.opacity(0.8) }

	// orange
	var orange1: Color { .init(hex: .orange1) }
	var orange2: Color { .init(hex: .orange2) }

	var red1: Color { .init(hex: .error) }

	// alert
	var error: Color { .init(hex: .error) }
	var lightError: Color { .init(hex: .lightError) }

	var buttonTextBlack: Color { .black }
	var buttonTextBlackTransparent: Color { .black.opacity(0.6) }

	var shadowBlack: Color { .black.opacity(0.08) }

	var cardShadowBlack: Color { .black.opacity(0.15) }

	// Approval gradient

	var gradientPurple: Color { .init(hex: 0xFF07E6) }
}

// MARK: - Color.Hex
extension Color {
	fileprivate enum Hex: UInt32 {
		// blue
		case blue1 = 0x060F8F
		case blue2 = 0x052CC0
		case blue3 = 0x20E4FF

		// green
		case green1 = 0x00AB84
		case green2 = 0x00C389
		case green3 = 0x21FFBE

		// gray
		case gray1 = 0x003057
		case gray2 = 0x8A8FA4
		case gray3 = 0xCED0D6
		case gray4 = 0xE2E5ED
		case gray5 = 0xF4F5F9

		// white
		case white = 0xFFFFFF

		// orange
		case orange1 = 0xF2AD21
		case orange2 = 0xEC633E

		case error = 0xC82020

		case lightError = 0xFCEBEB

		case notification = 0xF81B1B
	}
}

extension Double {
	fileprivate static let defaultOpacity: Self = 1
}

extension Color {
	fileprivate init(hex: Hex, opacity: Double = .defaultOpacity) {
		self.init(hex: hex.rawValue, opacity: opacity)
	}

	fileprivate init(hex: UInt32, opacity: Double = .defaultOpacity) {
		func value(shift: Int) -> Double {
			Double((hex >> shift) & 0xFF) / 255
		}

		self.init(
			red: value(shift: 16),
			green: value(shift: 08),
			blue: value(shift: 00),
			opacity: opacity
		)
	}

	init(
		red: UInt8,
		green: UInt8,
		blue: UInt8,
		opacity: Double = 1
	) {
		func value(_ byte: UInt8) -> Double {
			Double(byte) / Double(UInt8.max)
		}
		self.init(
			red: value(red),
			green: value(green),
			blue: value(blue),
			opacity: opacity
		)
	}

	static func randomDark(seed: Data?) -> Self {
		random(range: 40 ... 128, seed: seed)
	}

	static func randomLight(seed: Data?) -> Self {
		random(range: 128 ... 240, seed: seed)
	}

	private static func random(
		range: ClosedRange<UInt8> = 0 ... UInt8.max,
		seed: Data? = nil
	) -> Self {
		if let seed {
			randomSeeded(by: seed, range: range)
		} else {
			random(range: range)
		}
	}

	private static func random(
		range: ClosedRange<UInt8> = 0 ... UInt8.max
	) -> Self {
		Self(
			red: .random(in: range),
			green: .random(in: range),
			blue: .random(in: range),
			opacity: 1
		)
	}

	private static func randomSeeded(
		by seed: Data,
		range: ClosedRange<UInt8> = 0 ... UInt8.max
	) -> Self {
		var insecureRNG = InsecureRandomNumberGeneratorWithSeed(data: seed)
		func random() -> UInt8 {
			UInt8.random(in: range, using: &insecureRNG)
		}
		return Self(
			red: random(),
			green: random(),
			blue: random(),
			opacity: 1
		)
	}
}
