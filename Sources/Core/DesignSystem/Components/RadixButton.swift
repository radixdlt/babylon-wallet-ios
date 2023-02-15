import Resources
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

public extension ButtonStyle where Self == RadixButtonStyle {
	static var radix: RadixButtonStyle { .init(textColor: .app.gray1, backgroundColor: .app.gray4) }
	static var destructive: RadixButtonStyle { .init(textColor: .white, backgroundColor: .app.red1) }
}

// MARK: - RadixButtonStyle
public struct RadixButtonStyle: ButtonStyle {
	let textColor: Color
	let backgroundColor: Color

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.foregroundColor(textColor)
			.frame(maxWidth: .infinity)
			.frame(height: .standardButtonHeight)
			.background(backgroundColor.clipShape(.radixButton))
	}
}

extension Shape where Self == RoundedRectangle {
	static var radixButton: Self {
		RoundedRectangle(cornerRadius: .small1, style: .continuous)
	}
}
