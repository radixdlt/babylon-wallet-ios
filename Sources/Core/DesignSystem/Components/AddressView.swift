import Resources
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let address: String
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
		HStack(spacing: .zero) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.textStyle(.body2HighImportance)

			Button(
				action: copyAddressAction,
				label: {
					Image(asset: AssetResource.copy)
						.frame(.verySmall)
				}
			)
		}
	}
}
