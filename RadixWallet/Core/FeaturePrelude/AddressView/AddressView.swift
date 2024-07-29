// MARK: - AddressView
@MainActor
public struct AddressView: View {
	let identifiable: LedgerIdentifiable
	let isTappable: Bool
	let imageColor: Color?
	let isImageHidden: Bool
	private let showLocalIdOnly: Bool

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient

	@State private var sheet: Sheet?

	public init(
		_ identifiable: LedgerIdentifiable,
		showLocalIdOnly: Bool = false,
		isTappable: Bool = true,
		imageColor: Color? = nil,
		isImageHidden: Bool = false
	) {
		self.identifiable = identifiable
		self.showLocalIdOnly = showLocalIdOnly
		self.isTappable = isTappable
		self.imageColor = imageColor
		self.isImageHidden = isImageHidden
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
			switch identifiable {
			case let .address(address):
				addressView
					.onTapGesture {
						let store: StoreOf<AddressDetails> = .init(initialState: .init(address: address)) {
							AddressDetails()
						}
						sheet = .details(store)
					}
					.sheet(item: $sheet) { sheet in
						switch sheet {
						case let .details(store):
							AddressDetails.View(store: store)
						}
					}
			case .transaction:
				Menu {
					Button(L10n.AddressAction.copyTransactionId, image: .copyBig) {
						copyToPasteboard()
					}

					Button(L10n.AddressAction.viewOnDashboard, image: .iconLinkOut) {
						viewOnRadixDashboard()
					}
				} label: {
					addressView
				}
			}
		}
	}

	private var addressView: some View {
		HStack(spacing: .small3) {
			Text(formattedText)
				.lineLimit(1)

			if !isImageHidden {
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
		let imageResource: ImageResource =
			switch identifiable {
			case .address:
				.copy
			case .transaction:
				.iconLinkOut
			}
		return Image(imageResource)
	}

	private var formattedText: String {
		switch (showLocalIdOnly, identifiable) {
		case (true, let .address(.nonFungibleGlobalID(globalId))):
			globalId.nonFungibleLocalId.formatted(.default)
		default:
			identifiable.formatted(.default)
		}
	}
}

extension AddressView {
	private func copyToPasteboard() {
		pasteboardClient.copyString(identifiable.address)
	}

	private func viewOnRadixDashboard() {
		guard let path else { return }
		Task { [openURL, gatewaysClient] in
			let currentNetwork = await gatewaysClient.getCurrentGateway().network
			await openURL(
				RadixDashboard.dashboard(forNetwork: currentNetwork)
					.url
					.appending(path: path)
			)
		}
	}

	private var path: String? {
		identifiable.addressPrefix + "/" + identifiable.address
	}
}

// MARK: AddressView.Sheet
private extension AddressView {
	enum Sheet: Identifiable {
		case details(StoreOf<AddressDetails>)

		var id: String {
			switch self {
			case .details:
				"details"
			}
		}
	}
}

#if DEBUG
struct AddressView_Previews: PreviewProvider {
	static var previews: some View {
		AddressView(.address(.account(try! .init(validatingAddress: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"))))
	}
}
#endif
