//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

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
}

extension Color {
	enum Hex: UInt32 {
		case appGrey2 = 0x8A8FA4
	}
}

extension Double {
	static let defaultOpacity: Self = 1
}

extension Color {
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
