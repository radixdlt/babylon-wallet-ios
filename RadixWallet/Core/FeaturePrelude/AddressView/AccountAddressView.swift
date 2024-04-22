import SwiftUI

@MainActor
struct AccountAddressView: View {
	let address: AccountAddress
	let closeAction: () -> Void

	@State private var qrImage: Result<CGImage, Error>? = nil

	@Dependency(\.qrGeneratorClient) var qrGeneratorClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL

	var body: some View {
		VStack(spacing: .medium3) {
			top
			fullAddress
			viewOnDashboard
		}
		.padding([.horizontal, .bottom], .medium3)
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
	}

	private var fullAddress: some View {
		VStack(spacing: .large3) {
			VStack(spacing: .small2) {
				Text("Full address")
					.foregroundColor(.app.gray1)

				Text(address.address)
					.multilineTextAlignment(.center)
			}
			actions
		}
		.textStyle(.body1Header)
		.padding(.vertical, .medium1)
		.padding(.horizontal, .medium3)
		.background(Color.app.gray5)
		.cornerRadius(.small1)
	}

	private var actions: some View {
		HStack(spacing: .large3) {
			Button("Copy", image: .copy) {}

			Button("Enlarge", image: .copy) {}

			Button("Share", systemImage: "square.and.arrow.up") {}
		}
		.padding(.horizontal, .medium2)
		.foregroundColor(.app.gray1)
	}

	private var viewOnDashboard: some View {
		Button("View on Radix Dashboard", action: viewOnRadixDashboard)
			.buttonStyle(.secondaryRectangular(
				shouldExpand: true,
				trailingImage: .init(.iconLinkOut)
			))
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

	private func viewOnRadixDashboard() {
		Task { [openURL, gatewaysClient] in
			let path = "account/" + address.formatted(.raw)
			let currentNetwork = await gatewaysClient.getCurrentGateway().network
			await openURL(
				Radix.Dashboard.dashboard(forNetwork: currentNetwork)
					.url
					.appending(path: path)
			)
		}
	}
}
