// MARK: - AddressView
@MainActor
public struct AddressView: View {
	let identifiable: LedgerIdentifiable
	let isTappable: Bool
	let imageColor: Color?
	private let showFull: Bool

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient

	@State private var sheet: Sheet?

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
						let state = AddressDetails.State(address: address) {
							self.sheet = nil
						}
						let store: StoreOf<AddressDetails> = .init(initialState: state) {
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

	@ViewBuilder
	private var addressView: some View {
		if showFull {
			Text("\(identifiable.formatted(.full))\(image)")
				.lineLimit(nil)
				.multilineTextAlignment(.leading)
				.minimumScaleFactor(0.5)
		} else {
			HStack(spacing: .small3) {
				Text(compactedText)
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
		Image(.copy)
	}

	private var compactedText: String {
		switch identifiable {
		case let .address(.nonFungibleGlobalID(globalId)):
			globalId.nonFungibleLocalId.toUserFacingString()
		case .address, .transaction:
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
