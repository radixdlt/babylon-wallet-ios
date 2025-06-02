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
	// green
	var green1: Color { .init(hex: .green1) }
	var green2: Color { .init(hex: .green2) }
	var green3: Color { .init(hex: .green3) }

	/// white with 0.8 opacity
	var whiteTransparent: Color { .white.opacity(0.8) }

	// orange
	var orange2: Color { .init(hex: .orange2) }

	// alert
	var lightError: Color { .init(hex: .lightError) }

	var shadowBlack: Color { .black.opacity(0.08) }

	// Approval gradient

	var gradientPurple: Color { .init(hex: 0xFF07E6) }
}

// MARK: - Color.Hex
extension Color {
	fileprivate enum Hex: UInt32 {
		// green
		case green1 = 0x00AB84
		case green2 = 0x00C389
		case green3 = 0x21FFBE

		// orange
		case orange2 = 0xEC633E

		case lightError = 0xFCEBEB
	}
}

extension Double {
	fileprivate static let defaultOpacity: Self = 1
}

extension Color {
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (1, 1, 1, 0)
		}

		self.init(
			.sRGB,
			red: Double(r) / 255,
			green: Double(g) / 255,
			blue: Double(b) / 255,
			opacity: Double(a) / 255
		)
	}

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
