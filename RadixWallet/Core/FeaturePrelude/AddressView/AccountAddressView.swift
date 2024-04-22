import SwiftUI

struct AccountAddressView: View {
	let address: AccountAddress
	let closeAction: () -> Void

	@State private var qrImage: Result<CGImage, Error>? = nil

	@Dependency(\.qrGeneratorClient) var qrGeneratorClient

	var body: some View {
		VStack(spacing: .medium3) {
			top

			Spacer()
		}
		.withNavigationBar(closeAction: closeAction)
		.toolbar(.visible, for: .navigationBar)
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
		.task {
			await generateQrImage()
		}
	}

	private var top: some View {
		VStack(spacing: .small2) {
			Text("My Main Account")
				.textStyle(.sheetTitle)
				.foregroundColor(.app.gray1)

			Text("Address QR Code")
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)

			qrCode
				.padding(.horizontal, .large2)
		}
		.padding(.horizontal, .medium3)
	}

	private var qrCode: some View {
		ZStack {
			switch qrImage {
			case let .success(value):
				Image(decorative: value, scale: 1)
					.resizable()
					.aspectRatio(1, contentMode: .fit)
					.transition(.scale(scale: 0.95).combined(with: .opacity))
			case .failure:
				Text("Failed to generate QR code")
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.alert)
			case .none:
				ProgressView()
			}
		}
		.animation(.easeInOut, value: qrImage != nil)
	}

	private func generateQrImage() async {
		let content = QR.addressPrefix + address.address
		do {
			let image = try await qrGeneratorClient.generate(.init(content: content))
			self.qrImage = .success(image)
		} catch {
			self.qrImage = .failure(error)
		}
	}
}
