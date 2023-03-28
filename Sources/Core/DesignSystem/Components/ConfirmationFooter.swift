import SwiftUI

// MARK: - ConfirmationFooter
public struct ConfirmationFooter: View {
	public let title: String
	public let isEnabled: Bool // TODO: remove post betanet v2, just set .controlState from outside instead
	public let action: () -> Void

	@available(*, deprecated, message: "Use `.footer` instead")
	public init(
		title: String,
		isEnabled: Bool,
		action: @escaping () -> Void
	) {
		self.title = title
		self.isEnabled = isEnabled
		self.action = action
	}
}

extension ConfirmationFooter {
	public var body: some View {
		VStack(spacing: .zero) {
			Color.app.gray4.frame(height: 1)

			Button(title) {
				action()
			}
			.buttonStyle(.primaryRectangular)
			.controlState(isEnabled ? .enabled : .disabled)
			.padding([.top, .horizontal], .medium3)
			.padding(.bottom, .medium1)
		}
		.background(Color.app.background.edgesIgnoringSafeArea(.bottom))
	}
}

// MARK: - ConfirmationFooter_Previews
#if DEBUG
struct ConfirmationFooter_Previews: PreviewProvider {
	static var previews: some View {
		Color.red
			.safeAreaInset(edge: .bottom, spacing: .zero) {
				ConfirmationFooter(title: "Continue", isEnabled: true, action: {})
			}
	}
}
#endif
