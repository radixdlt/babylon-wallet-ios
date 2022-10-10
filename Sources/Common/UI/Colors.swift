import Foundation
import SwiftUI

public extension Color {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

public extension Color.App {
    // Old colors
    // TODO: refactor
    
	var backgroundDark: Color {
		.black
	}

	var backgroundLight: Color {
		.white
	}

	var secondary: Color {
		.init(hex: .gray2)
	}

	var notification: Color {
		.red
	}

	var buttonBackgroundLight: Color {
		.init(hex: .appGray3)
	}

	var cardBackgroundLight: Color {
		.init(hex: .appGray6)
	}

	var backgroundLightGray: Color {
		.init(hex: .appGray8)
	}

	var separatorLightGray: Color {
		.init(hex: .gray5)
	}

	var buttonBackgroundDark: Color {
		.init(hex: .appGray5)
	}

	var buttonBackgroundDark2: Color {
		.init(hex: .appGray10)
	}

	var buttonTextLight: Color {
		.init(hex: .gray4)
	}

	var tokenPlaceholderGray: Color {
		.init(hex: .appGray7)
	}

	var buttonTextDark: Color {
		.init(hex: .appCharcoal1)
	}

	var textFieldGray: Color {
		.init(hex: .appGray11)
	}

	var subtitleGray: Color {
		.init(hex: .appGray12)
	}

	var buttonDisabledGray: Color {
		.init(hex: .appGray13)
	}

	var buttonTextWhite: Color {
		.white
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
    
    // New colors
}

// MARK: - Color.Hex
private extension Color {
	enum Hex: UInt32 {
        // Old colors
        // TODO: refactor
		case appGray3 = 0xE2E2E2
		case appGray5 = 0xBEBDBD
		case appGray6 = 0xF4F4F4
		case appGray7 = 0xDDDCDC
		case appGray8 = 0xAFB1B7
		case appGray10 = 0x535353
		case appGray11 = 0xEFEFEF
		case appGray12 = 0x3D3D3D
		case appGray13 = 0xDDDDDD
		case appCharcoal1 = 0x414141
        
        // new colors
        case blue1 = 0x060F8F
        case blue2 = 0x052CC0
        case blue3 = 0x20E4FF
        
        case green1 = 0x00AB84
        case green2 = 0x00C389
        case green3 = 0x21FFBE
        
        case pink1 = 0xCE0D98
        case pink2 = 0xFF43CA
        
        case gray1 = 0x003057
        case gray2 = 0x8A8FA4
        case gray3 = 0xCED0D6
        case gray4 = 0xE2E5ED
        case gray5 = 0xF4F5F9
        
        case white = 0xFFFFFF
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
