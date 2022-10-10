import Address
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let address: Address
	let copyAddressAction: () -> Void

	public init(
		address: String,
		copyAddressAction: @escaping () -> Void
	) {
		self.address = address
		self.copyAddressAction = copyAddressAction
	}
}

public extension AddressView {
	var body: some View {
		HStack(spacing: 5) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.foregroundColor(.app.buttonTextBlackTransparent)
				.font(.app.body2Regular)

			Button(
				action: copyAddressAction,
				label: {
					Text(L10n.AccountList.Row.copyTitle)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.body2Regular)
						.underline()
						.padding(12)
						.fixedSize()
				}
			)
		}
	}
}
