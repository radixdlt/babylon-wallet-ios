import DesignSystem
import Profile
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
		HStack(spacing: 0) {
			Text(address.address)
				.lineLimit(1)
				.truncationMode(.middle)
				.textStyle(.body2HighImportance)

			Button(
				action: copyAddressAction,
				label: {
					Image("copy")
						.frame(width: 26, height: 26)
				}
			)
		}
	}
}
