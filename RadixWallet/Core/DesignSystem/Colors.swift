
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
	/// white with 0.3 opacity
	var whiteTransparent2: Color { .white.opacity(0.3) }
	/// white with 0.2 opacity
	var whiteTransparent3: Color { .white.opacity(0.2) }

	// orange
	var orange1: Color { .init(hex: .orange1) }
	var orange2: Color { .init(hex: .orange2) }

	var red1: Color { .init(hex: .error) }

	// alert
	var alert: Color { .init(hex: .alert) }
	var lightAlert: Color { .init(hex: .lightAlert) }
	var error: Color { .init(hex: .error) }
	var lightError: Color { .init(hex: .lightError) }
	var notification: Color { .init(hex: .notification) }

	var background: Color { .dynamic(light: .white, dark: .black) }
	@available(*, deprecated, message: "Use dynamic 'background' color instead")
	var backgroundDark: Color { .black }
	@available(*, deprecated, message: "Use dynamic 'background' color instead")
	var backgroundLight: Color { .white }

	var buttonTextBlack: Color { .black }
	var buttonTextBlackTransparent: Color { .black.opacity(0.6) }

	var shadowBlack: Color { .black.opacity(0.08) }

	var cardShadowBlack: Color { .black.opacity(0.15) }

	// Account gradient
	var account0green: Color { .init(hex: .account0green) }

	var account1pink: Color { .init(hex: .account1pink) }

	var account4pink: Color { .init(hex: .account4pink) }

	var account5blue: Color { .init(hex: .account5blue) }

	var account6green: Color { .init(hex: .account6green) }

	var account7pink: Color { .init(hex: .account7pink) }

	var account9green1: Color { .init(hex: .account9green1) }
	var account9green2: Color { .init(hex: .account9green2) }

	var account10pink1: Color { .init(hex: .account10pink1) }
	var account10pink2: Color { .init(hex: .account10pink2) }

	var account11green: Color { .init(hex: .account11green) }
	var account11blue1: Color { .init(hex: .account11blue1) }
	var account11pink: Color { .init(hex: .account11pink) }

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

		case alert = 0xE59700

		case lightAlert = 0xFFF4DF

		case error = 0xC82020

		case lightError = 0xFCEBEB

		case notification = 0xF81B1B

		// gradient
		case account0green = 0x01E2A0

		case account1pink = 0xFF43CA

		case account4pink = 0xCE0D98

		case account5blue = 0x0DCAE4

		case account6green = 0x03D497

		case account7pink = 0xF31DBE

		case account9green1 = 0x0BA97D
		case account9green2 = 0x1AF4B5

		case account10pink1 = 0x7E0D5F
		case account10pink2 = 0xE225B3

		case account11green = 0x03B797
		case account11blue1 = 0x1544F5
		case account11pink = 0x9937E3
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
