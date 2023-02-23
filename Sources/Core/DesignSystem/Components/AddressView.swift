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
			HStack(spacing: .small3) {
				Text(state.formattedAddress)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.textStyle(textStyle)

				if copyAddressAction != nil {
					Image(asset: AssetResource.copy)
						.foregroundColor(.app.gray2)
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
		public let formattedAddress: String

		public init(address: String) {
			self.formattedAddress = address
		}

		public init(address: String, format: AddressFormat) {
			self.formattedAddress = address.formatted(format)
		}
	}
}

extension String {
	public func formatted(_ format: AddressFormat = .default) -> String {
		let total = format.first + format.last
		if count <= total {
			return self
		} else {
			return prefix(format.first) + "..." + suffix(format.last)
		}
	}
}

// MARK: - AddressFormat
public struct AddressFormat {
	public let first: Int
	public let last: Int

	public static let `default` = Self(first: 4, last: 6)
}

#if DEBUG
struct AddressView_Previews: PreviewProvider {
	static var previews: some View {
		AddressView(
			AddressView.ViewState(
				address: "account_wqs8qxdx7qw8c",
				format: .default
			),
			copyAddressAction: nil
		)
	}
}
#endif
