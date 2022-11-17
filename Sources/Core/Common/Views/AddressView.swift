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
		HStack(spacing: .zero) {
			Text(address.address)
				.lineLimit(1)
				.truncationMode(.middle)
				.textStyle(.body2HighImportance)

			Button(
				action: copyAddressAction,
				label: {
					Image(asset: Asset.copy)
						.frame(width: 28, height: 28)
				}
			)
		}
	}
}
