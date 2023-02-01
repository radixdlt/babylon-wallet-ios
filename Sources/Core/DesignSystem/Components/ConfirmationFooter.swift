import SwiftUI

// MARK: - ConfirmationFooter
public struct ConfirmationFooter: View {
	public let title: String
	public let isEnabled: Bool
	public let action: () -> Void

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

public extension ConfirmationFooter {
	var body: some View {
		VStack(spacing: .zero) {
			Color.app.gray4
				.frame(height: 1)
				.padding(.bottom, .medium3)

			Button(title) {
				action()
			}
			.buttonStyle(.primaryRectangular)
			.controlState(isEnabled ? .enabled : .disabled)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}
	}
}

// MARK: - ConfirmationFooter_Previews
struct ConfirmationFooter_Previews: PreviewProvider {
	static var previews: some View {
		ConfirmationFooter(title: "proba", isEnabled: true, action: {})
	}
}
