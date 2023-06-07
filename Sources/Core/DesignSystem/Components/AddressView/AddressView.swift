import Prelude
import QRGeneratorClient
import Resources
import SharedModels
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let identifiable: LedgerIdentifiable
	let isTappable: Bool
	private let format: AddressFormat
	private let action: Action

	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient
	@Dependency(\.openURL) var openURL

	@State private var qrCodeContent: AccountAddress? = nil

	public init(
		_ identifiable: LedgerIdentifiable,
		isTappable: Bool = true
	) {
		self.identifiable = identifiable
		self.isTappable = isTappable

		switch identifiable {
		case .address:
			self.format = .default
			self.action = .copy
		case let .identifier(identifier):
			switch identifier {
			case .transaction:
				self.format = .default
				self.action = .viewOnDashboard
			case .nonFungibleGlobalID:
				self.format = .nonFungibleLocalId
				self.action = .copy
			}
		}
	}
}

extension AddressView {
	@ViewBuilder
	public var body: some View {
		if isTappable {
			tappableAddressView
				.sheet(item: $qrCodeContent) { accountAddress in
					AccountAddressQRCodePanel(address: accountAddress)
				}
		} else {
			addressView
		}
	}

	private var tappableAddressView: some View {
		Button {
			tapAction()
		} label: {
			HStack(spacing: .small3) {
				addressView
				image
			}
			.contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: .medium1))
			.contextMenu {
				Button(copyText, asset: AssetResource.copyBig) {
					copyToPasteboard()
				}

				Button(L10n.AddressAction.viewOnDashboard, asset: AssetResource.iconLinkOut) {
					viewOnRadixDashboard()
				}

				if case let .address(.account(accountAddress)) = identifiable {
					Button(L10n.AddressAction.showAccountQR, asset: AssetResource.qrCodeScanner) {
						showQR(for: accountAddress)
					}
				}
			}
		}
	}

	private var addressView: some View {
		Text((identifiable.address).formatted(format))
			.lineLimit(1)
			.minimumScaleFactor(0.5)
	}

	private var image: Image {
		Image(asset: action == .copy ? AssetResource.copy : AssetResource.iconLinkOut)
	}

	private var copyText: String {
		switch identifiable {
		case .address:
			return L10n.AddressAction.copyAddress
		case let .identifier(identifier):
			switch identifier {
			case .transaction:
				return L10n.AddressAction.copyTransactionId
			case .nonFungibleGlobalID:
				return L10n.AddressAction.copyNftId
			}
		}
	}
}

extension AddressView {
	private func tapAction() {
		action == .copy ? copyToPasteboard() : viewOnRadixDashboard()
	}

	private func copyToPasteboard() {
		pasteboardClient.copyString(identifiable.address)
	}

	private func viewOnRadixDashboard() {
		guard let addressURL else { return }
		Task { await openURL(addressURL) }
	}

	private func showQR(for accountAddress: AccountAddress) {
		qrCodeContent = accountAddress
	}

	private var path: String? {
		identifiable.addressPrefix + "/" + identifiable.address
	}

	private var addressURL: URL? {
		guard let path else { return nil }
		return Radix.Dashboard.default.url.appending(path: path)
	}
}

// MARK: AddressView.Action
extension AddressView {
	private enum Action {
		case copy
		case viewOnDashboard
	}
}

#if DEBUG
struct AddressView_Previews: PreviewProvider {
	static var previews: some View {
		AddressView(.address(.account(try! .init(address: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"))))
	}
}
#endif

// MARK: - AccountAddressQRCodePanel
public struct AccountAddressQRCodePanel: View {
	private let address: AccountAddress
	private let closeAction: (() -> Void)?

	public init(address: AccountAddress, closeAction: (() -> Void)? = nil) {
		self.address = address
		self.closeAction = closeAction
	}

	public var body: some View {
		VStack(spacing: 0) {
			if let closeAction {
				CloseButtonBar(action: closeAction)
			}
			QRCodeView(Self.prefix + address.address, size: Self.qrImageSize)
				.padding([.horizontal, .bottom], .large3)
				.padding(.top, topPadding)
		}
		.presentationDetents([.medium])
		.presentationDragIndicator(.visible)
	}

	private var topPadding: CGFloat {
		closeAction == nil ? .large3 : 0
	}

	private static let prefix: String = "radix:"
	private static let qrImageSize: CGFloat = 300
}

// MARK: - QRCodeView
public struct QRCodeView: View {
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient

	private let content: String
	private let size: CGSize
	@State private var qrImage: Result<CGImage, Error>? = nil

	public init(_ content: String, size: CGFloat) {
		self.content = content
		self.size = .init(width: size, height: size)
	}

	public var body: some View {
		ZStack {
			switch qrImage {
			case .none:
				Color.clear
			case let .success(value):
				Image(value, scale: 1, label: Text(L10n.AddressAction.QrCodeView.qrCodeLabel))
					.resizable()
					.aspectRatio(1, contentMode: .fit)
					.transition(.scale(scale: 0.95).combined(with: .opacity))
			case .failure:
				Text(L10n.AddressAction.QrCodeView.failureLabel)
					.foregroundColor(.app.alert)
					.textStyle(.body1HighImportance)
			}
		}
		.animation(.easeInOut, value: qrImage != nil)
		.task {
			do {
				let image = try await qrGeneratorClient.generate(.init(content: content, size: size))
				self.qrImage = .success(image)
			} catch {
				self.qrImage = .failure(error)
			}
		}
	}
}
