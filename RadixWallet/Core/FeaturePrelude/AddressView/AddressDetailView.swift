import SwiftUI

// MARK: - AddressDetailView
@MainActor
struct AddressDetailView: View {
	let address: LedgerIdentifiable.Address
	let closeAction: () -> Void

	@State private var title: Loadable<String?> = .idle
	@State private var qrImage: Result<CGImage, Error>? = nil
	@State private var showEnlargedView = false
	@State private var showShareView = false

	var body: some View {
		VStack(spacing: .zero) {
			top
			fullAddress
				.padding(.vertical, .medium3)
			bottom
			Spacer()
		}
		.multilineTextAlignment(.center)
		.padding([.horizontal, .bottom], .medium3)
		.overlay(alignment: .top) {
			overlay
		}
		.withNavigationBar(closeAction: closeAction)
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
		.task {
			await loadTitle()
			if showQrCode {
				await generateQrImage()
			}
		}
		.sheet(isPresented: $showShareView) {
			ShareView(items: [address.address])
		}
	}

	private var top: some View {
		VStack(spacing: .small2) {
			loadable(title) {
				ProgressView()
			} successContent: { title in
				Text(title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
			}

			if showQrCode {
				Text("Address QR Code")
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)

				qrCode
					.padding(.horizontal, .large2)
			}
		}
	}

	private var fullAddress: some View {
		VStack(spacing: .medium2) {
			VStack(spacing: .small2) {
				Text("Full address")
					.foregroundColor(.app.gray1)
				colorisedAddress
			}
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
		let content = address.address.dropFirst(5).dropLast(6)

		var attributedStr = AttributedString(address.address, foregroundColor: .app.gray1)
		if let range = attributedStr.range(of: content) {
			attributedStr[range].foregroundColor = .app.gray2
		}
		return Text(attributedStr)
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

	private var bottom: some View {
		VStack(spacing: .medium3) {
			Button("View on Radix Dashboard", action: viewOnRadixDashboard)
				.buttonStyle(
					.secondaryRectangular(
						shouldExpand: true,
						trailingImage: .init(.iconLinkOut)
					)
				)
			if let addressToVerifyOnLedger {
				Button("Verify Address on Ledger Device") {
					verifyOnLedger(address: addressToVerifyOnLedger)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
			}
		}
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
}

// MARK: - Enlarged view
private extension AddressDetailView {
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

// MARK: - Business logic
private extension AddressDetailView {
	func generateQrImage() async {
		@Dependency(\.qrGeneratorClient) var qrGeneratorClient
		let content = QR.addressPrefix + address.address
		do {
			let image = try await qrGeneratorClient.generate(.init(content: content))
			self.qrImage = .success(image)
		} catch {
			self.qrImage = .failure(error)
		}
	}

	func loadTitle() async {
		title = .loading
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		do {
			switch address {
			case let .account(value, _):
				let res = try await accountsClient.getAccountByAddress(value)
				title = .success(res.displayName.rawValue)
			case let .resource(address):
				let res = try await onLedgerEntitiesClient.getResource(address)
				title = .success(res.resourceTitle)
			case let .validator(address):
				let res = try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys)
				title = .success(res.metadata?.name)
			case let .package(address):
				let res = try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys)
				title = .success(res.metadata?.name)
			case let .resourcePool(address):
				let res = try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys)
				title = .success(res.metadata?.name)
			case let .component(address):
				let res = try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys)
				title = .success(res.metadata?.name)
			case .nonFungibleGlobalID:
				title = .success(nil)
			}
		} catch {
			title = .failure(error)
		}
	}
}

// MARK: - Actions
private extension AddressDetailView {
	func copy() {
		@Dependency(\.pasteboardClient) var pasteboardClient
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
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.openURL) var openURL
		let path = address.addressPrefix + "/" + address.formatted(.raw)

		Task {
			let currentNetwork = await gatewaysClient.getCurrentGateway().network
			await openURL(
				Radix.Dashboard.dashboard(forNetwork: currentNetwork)
					.url
					.appending(path: path)
			)
		}
	}

	func verifyOnLedger(address: AccountAddress) {
		@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
		ledgerHardwareWalletClient.verifyAddress(of: address)
	}
}

// MARK: - Helpers
private extension AddressDetailView {
	var showQrCode: Bool {
		switch address {
		case .account:
			true
		default:
			false
		}
	}

	var addressToVerifyOnLedger: AccountAddress? {
		switch address {
		case let .account(address, isLedgerHWAccount):
			isLedgerHWAccount ? address : nil
		default:
			nil
		}
	}
}

private extension OnLedgerEntity.Resource {
	var resourceTitle: String? {
		guard let name = metadata.name else {
			return metadata.symbol
		}
		guard let symbol = metadata.symbol else {
			return name
		}
		return "\(name) (\(symbol))"
	}
}
