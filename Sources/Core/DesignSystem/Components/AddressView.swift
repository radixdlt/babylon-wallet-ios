import Resources
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let address: String
	let textStyle: TextStyle
	let copyAddressAction: (() -> Void)?

	public init(
		address: String,
		textStyle: TextStyle = .body2HighImportance,
		copyAddressAction: @escaping () -> Void
	) {
		self.address = address
		self.textStyle = textStyle
		self.copyAddressAction = copyAddressAction
	}
}

public extension AddressView {
	var body: some View {
		HStack(spacing: .zero) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.textStyle(textStyle)

			if let copyAddressAction = copyAddressAction {
				Button(
					action: copyAddressAction,
					label: {
						Image(asset: AssetResource.copy)
							.frame(width: 28, height: 28)
					}
				)
			}
		}
	}
}
