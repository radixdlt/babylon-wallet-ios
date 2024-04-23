// MARK: - AddressView
@MainActor
public struct AddressView: View {
	let identifiable: LedgerIdentifiable
	let isTappable: Bool
	let imageColor: Color?
	private let showFull: Bool
	private let action: Action

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	@State private var accountAddress: AccountAddress? = nil

	public init(
		_ identifiable: LedgerIdentifiable,
		showFull: Bool = false,
		isTappable: Bool = true,
		imageColor: Color? = nil
	) {
		self.identifiable = identifiable
		self.showFull = showFull
		self.isTappable = isTappable
		self.imageColor = imageColor

		switch identifiable {
		case .address, .identifier(.nonFungibleGlobalID):
			self.action = .copy
		case .identifier(.transaction):
			self.action = .viewOnDashboard
		}
	}
}

extension AddressView {
	@ViewBuilder
	public var body: some View {
		if isTappable {
			tappableAddressView
		} else {
			addressView
		}
	}

	private var tappableAddressView: some View {
		Group {
			if case let .address(.account(accountAddress, _)) = identifiable {
				addressView
					.onTapGesture {
						self.accountAddress = accountAddress
					}
					.onLongPressGesture(perform: longPressGesture)
					.sheet(item: $accountAddress) { address in
						AccountAddressView(address: address) {
							self.accountAddress = nil
						}
					}
			} else {
				Menu {
					Button(copyText, image: .copyBig) {
						copyToPasteboard()
					}

					Button(L10n.AddressAction.viewOnDashboard, image: .iconLinkOut) {
						viewOnRadixDashboard()
					}
				} label: {
					addressView
				}
				.onLongPressGesture(perform: longPressGesture)
			}
		}
	}

	@ViewBuilder
	private var addressView: some View {
		if showFull {
			Text("\(identifiable.formatted(.full))\(image)")
				.lineLimit(nil)
				.multilineTextAlignment(.leading)
				.minimumScaleFactor(0.5)
		} else {
			HStack(spacing: .small3) {
				Text(identifiable.formatted(.default))
					.lineLimit(1)
				if let imageColor {
					image
						.foregroundStyle(imageColor)
				} else {
					image
				}
			}
		}
	}

	private var image: Image {
		Image(action == .copy ? ImageResource.copy : .iconLinkOut)
	}

	private var copyText: String {
		switch identifiable {
		case .address:
			L10n.AddressAction.copyAddress
		case let .identifier(identifier):
			switch identifier {
			case .transaction:
				L10n.AddressAction.copyTransactionId
			case .nonFungibleGlobalID:
				L10n.AddressAction.copyNftId
			}
		}
	}

	func verifyAddressOnLedger(_ accountAddress: AccountAddress) {
		ledgerHardwareWalletClient.verifyAddress(of: accountAddress)
	}
}

extension AddressView {
	private func longPressGesture() {
		action == .copy ? copyToPasteboard() : viewOnRadixDashboard()
	}

	private func copyToPasteboard() {
		pasteboardClient.copyString(identifiable.address)
	}

	private func viewOnRadixDashboard() {
		guard let path else { return }
		Task { [openURL, gatewaysClient] in
			let currentNetwork = await gatewaysClient.getCurrentGateway().network
			await openURL(
				Radix.Dashboard.dashboard(forNetwork: currentNetwork)
					.url
					.appending(path: path)
			)
		}
	}

	private var path: String? {
		identifiable.addressPrefix + "/" + identifiable.address
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
		AddressView(.address(.account(try! .init(validatingAddress: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"))))
	}
}
#endif
