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
			HStack(spacing: 0) {
				Text(accountName)
					.textStyle(.body1Header)
					.foregroundColor(.app.white)
				Spacer(minLength: 0)
				Text(address.formatted(.short))
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.whiteTransparent)
			}
			.padding(.horizontal, .large2)
			.frame(height: .standardButtonHeight)
			.background {
				LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
					.clipShape(.radixButton)
			}
		}
	}
}
