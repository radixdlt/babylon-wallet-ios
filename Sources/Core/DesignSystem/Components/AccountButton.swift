import SwiftUI

// MARK: - AccountButton
/// An account button with the given address and gradient
public struct AccountButton: View {
	let accountName: String
	let address: String
	let gradient: Gradient
	let action: () -> Void

	public init(_ accountName: String, address: String, gradient: Gradient, action: @escaping () -> Void) {
		self.accountName = accountName
		self.address = address
		self.gradient = gradient
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			AccountLabel(accountName, address: address, gradient: gradient, height: .standardButtonHeight)
				.cornerRadius(.small2)
		}
		.buttonStyle(DarkenWhenPressed())
	}

	private struct DarkenWhenPressed: ButtonStyle {
		@Environment(\.controlState) var controlState

		public func makeBody(configuration: Configuration) -> some View {
			configuration.label
				.brightness(configuration.isPressed ? -0.1 : 0)
		}
	}
}

// MARK: - AccountLabel
public struct AccountLabel: View {
	let accountName: String
	let address: String
	let gradient: Gradient
	let height: CGFloat
	let copyAction: (() -> Void)?

	public init(_ accountName: String, address: String, gradient: Gradient, height: CGFloat, copyAction: (() -> Void)? = nil) {
		self.accountName = accountName
		self.address = address
		self.gradient = gradient
		self.height = height
		self.copyAction = copyAction
	}

	public var body: some View {
		HStack(spacing: 0) {
			Text(accountName)
				.textStyle(.body1Header)
				.foregroundColor(.app.white)
			Spacer(minLength: 0)
			AddressView(.init(address: address, format: .default), copyAddressAction: copyAction)
				.foregroundColor(.app.whiteTransparent)
		}
		.padding(.horizontal, .medium3)
		.frame(height: height)
		.background {
			LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
		}
	}
}
