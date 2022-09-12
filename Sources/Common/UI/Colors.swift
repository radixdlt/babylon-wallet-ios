import Foundation
import SwiftUI

public extension Color {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

public extension Color.App {
	var backgroundDark: Color {
		.black
	}

	var backgroundLight: Color {
		.white
	}

	var secondary: Color {
		.init(hex: .appGrey2)
	}

	var notification: Color {
		.red
	}

	var buttonBackgroundLight: Color {
		.init(hex: .appGrey3)
	}

	var cardBackgroundLight: Color {
		.init(hex: .appGrey6)
	}

	var backgroundLightGray: Color {
		.init(hex: .appGrey8)
	}

	var separatorLightGray: Color {
		.init(hex: .appGrey9)
	}

	var buttonBackgroundDark: Color {
		.init(hex: .appGrey5)
	}

	var buttonTextLight: Color {
		.init(hex: .appGrey4)
	}

	var tokenPlaceholderGray: Color {
		.init(hex: .appGrey7)
	}

	var buttonTextDark: Color {
		.init(hex: .appCharcoal1)
	}

	var buttonTextBlack: Color {
		.black
	}

	var buttonTextBlackTransparent: Color {
		.black.opacity(0.6)
	}
}

private extension Color {
	enum Hex: UInt32 {
		case appGrey2 = 0x8A8FA4
		case appGrey3 = 0xE2E2E2
		case appGrey4 = 0xE2E5ED
		case appGrey5 = 0xBEBDBD
		case appGrey6 = 0xF4F4F4
		case appGrey7 = 0xDDDCDC
		case appGrey8 = 0xAFB1B7
		case appGrey9 = 0xF4F5F9
		case appCharcoal1 = 0x414141
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

#if DEBUG
public extension Color.App {
	static var random: Color {
		Color(
			red: .random(in: 0 ... 1),
			green: .random(in: 0 ... 1),
			blue: .random(in: 0 ... 1)
		)
	}
}
#endif
