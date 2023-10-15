// MARK: - QRGeneratorClient + DependencyKey
extension QRGeneratorClient: DependencyKey {
	public static let liveValue = QRGeneratorClient(generate: generateImage)
}

@Sendable
private func generateImage(_ intent: GenerateQRImageIntent) async throws -> CGImage {
	try await Task(priority: .background) {
		try syncGenerateQR(
			data: intent.data,
			size: intent.size,
			inputCorrectionLevel: intent.inputCorrectionLevel.value
		)
	}.value
}

private func syncGenerateQR(
	data: Data,
	size: CGSize,
	inputCorrectionLevel: String
) throws -> CGImage {
	let filter = CIFilter.qrCodeGenerator()

	filter.message = data
	filter.correctionLevel = inputCorrectionLevel

	guard let outputImage = filter.outputImage else {
		throw GenerateQRImageError.failedToGenerate
	}

	let x = size.width / outputImage.extent.size.width
	let y = size.height / outputImage.extent.size.height
	let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: x, y: y))

	guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else {
		throw GenerateQRImageError.failedToConvertToCGImage
	}

	return cgImage
}
