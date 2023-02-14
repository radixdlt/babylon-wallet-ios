import Prelude
import SwiftUI

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
	public struct App { fileprivate init() {} }
	public static let app = App()
}

extension Color.App {
	// blue
	public var blue1: Color { .init(hex: .blue1) }
	public var blue2: Color { .init(hex: .blue2) }
	public var blue3: Color { .init(hex: .blue3) }

	// green
	public var green1: Color { .init(hex: .green1) }
	public var green2: Color { .init(hex: .green2) }
	public var green3: Color { .init(hex: .green3) }

	// gray
	public var gray1: Color { .init(hex: .gray1) }
	public var gray2: Color { .init(hex: .gray2) }
	public var gray3: Color { .init(hex: .gray3) }
	public var gray4: Color { .init(hex: .gray4) }
	public var gray5: Color { .init(hex: .gray5) }

	// white
	public var white: Color { .init(hex: .white) }
	public var whiteTransparent: Color { .white.opacity(0.8) }

	// orange
	public var orange1: Color { .init(hex: .orange1) }
	public var orange2: Color { .init(hex: .orange2) }

	// alert
	public var red1: Color { .init(hex: .red1) }

	public var background: Color { .dynamic(light: .white, dark: .black) }
	@available(*, deprecated, message: "Use dynamic 'background' color instead")
	public var backgroundDark: Color { .black }
	@available(*, deprecated, message: "Use dynamic 'background' color instead")
	public var backgroundLight: Color { .white }

	public var notification: Color { .init(hex: .red1) }

	public var buttonTextBlack: Color { .black }
	public var buttonTextBlackTransparent: Color { .black.opacity(0.6) }

	public var shadowBlack: Color { .black.opacity(0.08) }

	// gradient
	public var account0green: Color { .init(hex: .account0green) }

	public var account1pink: Color { .init(hex: .account1pink) }

	public var account4pink: Color { .init(hex: .account4pink) }

	public var account5blue: Color { .init(hex: .account5blue) }

	public var account6green: Color { .init(hex: .account6green) }

	public var account7pink: Color { .init(hex: .account7pink) }

	public var account9green1: Color { .init(hex: .account9green1) }
	public var account9green2: Color { .init(hex: .account9green2) }

	public var account10pink1: Color { .init(hex: .account10pink1) }
	public var account10pink2: Color { .init(hex: .account10pink2) }

	public var account11green: Color { .init(hex: .account11green) }
	public var account11blue1: Color { .init(hex: .account11blue1) }
	public var account11pink: Color { .init(hex: .account11pink) }
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

		// alert
		case red1 = 0xC82020

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
}

extension Color.App {
	public static var random: Color {
		Color(
			red: .random(in: 0 ... 1),
			green: .random(in: 0 ... 1),
			blue: .random(in: 0 ... 1)
		)
	}
}
