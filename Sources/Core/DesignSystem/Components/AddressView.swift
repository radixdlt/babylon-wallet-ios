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
		copyAddressAction: (() -> Void)? = nil
	) {
		self.state = state
		self.textStyle = textStyle
		self.copyAddressAction = copyAddressAction
	}
}

extension AddressView {
	public var body: some View {
		Button(action: copyAddressAction ?? {}) {
			HStack(spacing: .small2) {
				Text(state.formattedAddress)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.textStyle(textStyle)

				if copyAddressAction != nil {
					Image(asset: AssetResource.copy)
				}
			}
		}
		.controlState(controlState)
	}

	public var controlState: ControlState {
		copyAddressAction != nil ? .enabled : .disabled
	}
}

// MARK: AddressView.ViewState
extension AddressView {
	public struct ViewState: Equatable {
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
			case .full:
				formattedAddress = address
			}
		}
	}
}

// MARK: - AddressView.ViewState.AddressFormat
extension AddressView.ViewState {
	public enum AddressFormat {
		case short(ShortAddressFormat = .default)
		case full
	}
}

// MARK: - AddressView.ViewState.AddressFormat.ShortAddressFormat
extension AddressView.ViewState.AddressFormat {
	public struct ShortAddressFormat {
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
				address: "account_wqs8qxdx7qw8c",
				format: .short()
			),
			copyAddressAction: nil
		)
	}
}
#endif
