import Prelude
import Resources
import SharedModels
import SwiftUI

// MARK: - AddressView
public struct AddressView: SwiftUI.View, Sendable {
	let identifiable: LedgerIdentifiable
	let isTappable: Bool
	private let format: AddressFormat
	private let action: Action

	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.openURL) var openURL

	public init(
		_ identifiable: LedgerIdentifiable,
		isTappable: Bool = true
	) {
		self.identifiable = identifiable
		self.isTappable = isTappable

		switch identifiable {
		case .address:
			format = .default
			action = .copy
		case let .identifier(identifier):
			switch identifier {
			case .transaction:
				format = .default
				action = .viewOnDashboard
			case .nonFungibleGlobalID:
				format = .nonFungibleLocalId
				action = .copy
			}
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

	private var path: String? {
		identifiable.addressPrefix + "/" + identifiable.address
	}

	private var addressURL: URL? {
		guard let path else { return nil }
		return Radix.Dashboard.rcnet.url.appending(path: path)
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
