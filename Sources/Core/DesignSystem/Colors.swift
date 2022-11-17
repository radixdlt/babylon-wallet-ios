import Foundation
import SwiftUI

public extension Color {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

public extension Color.App {
	// blue
	var blue1: Color {
		.init(hex: .blue1)
	}

	var blue2: Color {
		.init(hex: .blue2)
	}

	var blue3: Color {
		.init(hex: .blue3)
	}

	// green
	var green1: Color {
		.init(hex: .green1)
	}

	var green2: Color {
		.init(hex: .green2)
	}

	var green3: Color {
		.init(hex: .green3)
	}

	// gray
	var gray1: Color {
		.init(hex: .gray1)
	}

	var gray2: Color {
		.init(hex: .gray2)
	}

	var gray3: Color {
		.init(hex: .gray3)
	}

	var gray4: Color {
		.init(hex: .gray4)
	}

	var gray5: Color {
		.init(hex: .gray5)
	}

	// white
	var white: Color {
		.init(hex: .white)
	}

	var whiteTransparent: Color {
		.white.opacity(0.8)
	}

	var backgroundDark: Color {
		.black
	}

	var backgroundLight: Color {
		.white
	}

	var notification: Color {
		.init(hex: .red1)
	}

	var buttonTextBlack: Color {
		.black
	}

	var buttonTextBlackTransparent: Color {
		.black.opacity(0.6)
	}

	var shadowBlack: Color {
		.black.opacity(0.08)
	}

	// gradient
	var account1green: Color {
		.init(hex: .account1green)
	}
}

// MARK: - Color.Hex
private extension Color {
	enum Hex: UInt32 {
		// blue
		case blue1 = 0x060F8F
		case blue2 = 0x052CC0
		case blue3 = 0x20E4FF

		// green
		case green1 = 0x00AB84
		case green2 = 0x00C389
		case green3 = 0x21FFBE

		// pink
		case pink1 = 0xCE0D98
		case pink2 = 0xFF43CA

		// gray
		case gray1 = 0x003057
		case gray2 = 0x8A8FA4
		case gray3 = 0xCED0D6
		case gray4 = 0xE2E5ED
		case gray5 = 0xF4F5F9

		// white
		case white = 0xFFFFFF

		// alert
		case orange1 = 0xF2AD21
		case red1 = 0xC82020

		// gradient
		case account1green = 0x01E2A0
	}
}

private extension Double {
	static let defaultOpacity: Self = 1
}

private extension Color {
	init(hex: Hex, opacity: Double = .defaultOpacity) {
		self.init(hex: hex.rawValue, opacity: opacity)
	}

	init(hex: UInt32, opacity: Double = .defaultOpacity) {
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

public extension Color.App {
	static var random: Color {
		Color(
			red: .random(in: 0 ... 1),
			green: .random(in: 0 ... 1),
			blue: .random(in: 0 ... 1)
		)
	}
}
