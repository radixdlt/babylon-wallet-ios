import SwiftUI

// MARK: - AccountAddressView
@MainActor
struct AccountAddressView: View {
	let address: AccountAddress
	let closeAction: () -> Void

	@State private var qrImage: Result<CGImage, Error>? = nil
	@State private var showEnlargedView = false
	@State private var showShareView = false

	@Dependency(\.qrGeneratorClient) var qrGeneratorClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.openURL) var openURL

	var body: some View {
		VStack(spacing: .medium3) {
			top
			fullAddress
			viewOnDashboard
		}
		.padding([.horizontal, .bottom], .medium3)
		.overlay(alignment: .top) {
			overlay
		}
		.withNavigationBar(closeAction: closeAction)
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
		.task {
			await generateQrImage()
		}
		.sheet(isPresented: $showShareView) {
			ShareView(items: [address.address])
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
				colorisedAddress
			}
			.multilineTextAlignment(.center)
			actions
		}
		.textStyle(.body1Header)
		.padding(.vertical, .medium1)
		.padding(.horizontal, .medium3)
		.background(Color.app.gray5)
		.cornerRadius(.small1)
	}

	private var colorisedAddress: some View {
		// TODO: The logic to return the colorised part should come from Sargon.
		var content = address.address
		let start = content.prefix(5)
		content = String(content.dropFirst(5))
		let end = content.suffix(6)
		content = String(content.dropLast(6))

		return Text(start)
			.foregroundColor(.app.gray1)
			+ Text(content)
			.foregroundColor(.app.gray2)
			+ Text(end)
			.foregroundColor(.app.gray1)
	}

	private var actions: some View {
		HStack(spacing: .large3) {
			Button("Copy", image: .copy, action: copy)
			Button("Enlarge", image: .fullScreen) {
				showEnlargedView(true)
			}
			Button("Share", systemImage: "square.and.arrow.up", action: share)
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
}

// MARK: - Enlarged view
private extension AccountAddressView {
	var overlay: some View {
		Group {
			if showEnlargedView {
				enlargedView
					.onTapGesture {
						showEnlargedView(false)
					}
					.background(enlargedViewBackrgound)
			}
		}
	}

	var enlargedView: some View {
		Group {
			Text(enlargedText)
				.textStyle(.enlarged)
				.foregroundColor(.app.white)
		}
		.multilineTextAlignment(.center)
		.padding(.small1)
		.background(.app.gray1.opacity(0.8))
		.cornerRadius(.small1)
		.padding(.horizontal, .large2)
	}

	private var enlargedText: AttributedString {
		let attributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.app.green3)]
		let result = NSMutableAttributedString()
		for letter in address.address.unicodeScalars {
			let isDigit = CharacterSet.decimalDigits.contains(letter)
			result.append(.init(
				string: String(letter),
				attributes: isDigit ? attributes : nil
			))
		}

		return .init(result)
	}

	private var enlargedViewBackrgound: some View {
		Color.black.opacity(0.2)
			.frame(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
			.contentShape(Rectangle())
			.onTapGesture {
				showEnlargedView(false)
			}
	}
}

extension String {
	var rangesOfDigits: [NSRange] {
		var ranges = [NSRange]()
		var range = NSRange(location: 0, length: count)
		while range.location != NSNotFound {
			range = (self as NSString).rangeOfCharacter(from: .decimalDigits)
			if range.location != NSNotFound {
				ranges.append(range)
				range = NSRange(location: range.location + range.length,
				                length: count - (range.location + range.length))
			}
		}
		return ranges
	}
}

// MARK: - Actions
private extension AccountAddressView {
	func copy() {
		pasteboardClient.copyString(address.address)
	}

	func showEnlargedView(_ value: Bool) {
		withAnimation {
			showEnlargedView = value
		}
	}

	func share() {
		showShareView = true
	}

	func viewOnRadixDashboard() {
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
