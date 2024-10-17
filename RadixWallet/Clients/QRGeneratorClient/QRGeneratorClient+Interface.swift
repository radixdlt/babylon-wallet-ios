// MARK: - QRGeneratorClient
struct QRGeneratorClient: Sendable {
	var generate: Generate

	init(
		generate: @escaping Generate
	) {
		self.generate = generate
	}
}

// MARK: QRGeneratorClient.Generate
extension QRGeneratorClient {
	typealias Generate = @Sendable (GenerateQRImageIntent) async throws -> CGImage
}

// MARK: - GenerateQRImageIntent
struct GenerateQRImageIntent: Sendable {
	let data: Data
	let inputCorrectionLevel: InputCorrectionLevel
	let size: CGSize

	init(
		data: Data,
		inputCorrectionLevel: InputCorrectionLevel = .default,
		size: CGSize? = nil
	) {
		self.data = data
		self.inputCorrectionLevel = inputCorrectionLevel
		self.size = size ?? Self.defaultSize
	}
}

extension GenerateQRImageIntent {
	static let defaultSize: CGSize = .init(width: 300, height: 300)

	init(
		content: String,
		encoding: String.Encoding = .utf8,
		inputCorrectionLevel: InputCorrectionLevel = .default,
		size: CGSize? = nil
	) {
		self.init(
			data: content.data(using: encoding)!,
			inputCorrectionLevel: inputCorrectionLevel,
			size: size
		)
	}

	init(
		content: String,
		encoding: String.Encoding = .utf8,
		inputCorrectionLevel: InputCorrectionLevel = .default,
		size: CGFloat
	) {
		self.init(
			content: content,
			encoding: encoding,
			inputCorrectionLevel: inputCorrectionLevel,
			size: .init(width: size, height: size)
		)
	}
}

// MARK: GenerateQRImageIntent.InputCorrectionLevel
extension GenerateQRImageIntent {
	enum InputCorrectionLevel: Int, Sendable, Hashable, CustomStringConvertible {
		/// Level Low 7%.
		case low7 = 7

		/// Level Medium 15%.
		case medium15 = 15

		/// Level Q 25%
		case q = 25

		/// Level High 30%.
		case high30 = 30

		static let `default`: Self = .medium15

		var description: String {
			switch self {
			case .low7: "L 7"
			case .medium15: "M 15"
			case .q: "Q 25"
			case .high30: "H 30"
			}
		}

		var value: String {
			switch self {
			case .high30: "H"
			case .low7: "L"
			case .q: "Q"
			case .medium15: "M"
			}
		}
	}
}

// MARK: - GenerateQRImageError
enum GenerateQRImageError: Equatable, LocalizedError {
	case failedToGenerate
	case failedToConvertToCGImage

	var errorDescription: String? {
		switch self {
		case .failedToGenerate:
			"Failed to generate QR image, reason unknown."
		case .failedToConvertToCGImage:
			"Failed to convert to CGImage."
		}
	}
}
