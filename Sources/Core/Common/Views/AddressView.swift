import DesignSystem
import Profile
import Resources
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let address: Address
	let copyAddressAction: () -> Void

	public init(
		address: Address,
		copyAddressAction: @escaping () -> Void
	) {
		self.address = address
		self.copyAddressAction = copyAddressAction
	}
}

public extension AddressView {
	var body: some View {
		HStack(spacing: 5) {
			Text(address.address)
				.lineLimit(1)
				.truncationMode(.middle)
				.foregroundColor(.app.buttonTextBlackTransparent)
				.textStyle(.body2Regular)

			Button(
				action: copyAddressAction,
				label: {
					Text(L10n.AccountList.Row.copyTitle)
						.foregroundColor(.app.buttonTextBlack)
						.underline()
						.textStyle(.body2Regular)
						.padding(12)
						.fixedSize()
				}
			)
		}
	}
}
