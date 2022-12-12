import Resources
import SwiftUI

// MARK: - AddressView
public struct AddressView: View {
	let state: ViewState
	let textStyle: TextStyle
	let copyAddressAction: (() -> Void)?

	public init(
		_ state: ViewState,
		textStyle: TextStyle = .body2HighImportance,
		copyAddressAction: (() -> Void)?
	) {
		self.state = state
		self.textStyle = textStyle
		self.copyAddressAction = copyAddressAction
	}
}

public extension AddressView {
	var body: some View {
		HStack(spacing: .zero) {
			Text(state.formattedAddress)
				.lineLimit(1)
				.minimumScaleFactor(0.5)
				.textStyle(textStyle)

			if let copyAddressAction {
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
}

// MARK: AddressView.ViewState
public extension AddressView {
	struct ViewState: Equatable {
		public var formattedAddress: String

		public init(address: String, format: AddressFormat) {
			switch format {
			case let .short(format):
				let total = format.first + format.last
				if address.count <= total {
					formattedAddress = address
				} else {
					formattedAddress = address.prefix(format.first) + "..." + address.suffix(format.last)
				}
			}
		}
	}
}

// MARK: - AddressView.ViewState.AddressFormat
public extension AddressView.ViewState {
	enum AddressFormat {
		case short(ShortAddressFormat = .default)
	}
}

// MARK: - AddressView.ViewState.AddressFormat.ShortAddressFormat
public extension AddressView.ViewState.AddressFormat {
	struct ShortAddressFormat {
		var first: Int
		var last: Int

		public static let `default` = Self(first: 4, last: 6)
	}
}

#if DEBUG
struct AddressView_Previews: PreviewProvider {
	static var previews: some View {
		AddressView(
			AddressView.ViewState(
				componentAddress: "account_wqs8qxdx7qw8c",
				format: .short()
			),
			copyAddressAction: nil
		)
	}
}
#endif
