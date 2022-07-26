//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Foundation
import SwiftUI

public extension Color {
	static let appBackgroundDark: Self = .black
	static let appBackgroundLight: Self = .white
	static let appGrey2 = Self(hex: .appGrey2)
}

extension Double {
	static let defaultOpacity: Self = 1
}

extension Color {
	enum Hex: UInt32 {
		case appGrey2 = 0x8A8FA4
	}

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
