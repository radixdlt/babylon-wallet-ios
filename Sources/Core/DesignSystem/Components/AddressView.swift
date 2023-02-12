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

public extension AddressView {
	var body: some View {
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

	var controlState: ControlState {
		copyAddressAction != nil ? .enabled : .disabled
	}
}

// MARK: AddressView.ViewState
public extension AddressView {
	struct ViewState: Equatable {
		public let formattedAddress: String

		public init(address: String, format: AddressFormat) {
			self.formattedAddress = address.formatted(format)
		}
	}
}

// TODO: • Move somewhere else

public extension String {
	func formatted(_ format: AddressFormat) -> String {
		switch format {
		case let .short(format):
			let total = format.first + format.last
			if count <= total {
				return self
			} else {
				return prefix(format.first) + "..." + suffix(format.last)
			}
		case .full:
			return self
		}
	}
}

// MARK: - AddressFormat
public enum AddressFormat {
	case short(ShortAddressFormat = .default)
	case full

	public static let short = AddressFormat.short(.default)
}

// MARK: AddressFormat.ShortAddressFormat
public extension AddressFormat {
	struct ShortAddressFormat {
		public var first: Int
		public var last: Int

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
