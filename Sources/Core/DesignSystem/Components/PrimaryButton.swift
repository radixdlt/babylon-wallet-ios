import SwiftUI

// MARK: - PrimaryButton
public struct PrimaryButton: View {
	let title: String
	let isEnabled: Bool
	let action: () -> Void

	public init(
		title: String,
		isEnabled: Bool = true,
		action: @escaping () -> Void
	) {
		self.title = title
		self.isEnabled = isEnabled
		self.action = action
	}
}

public extension PrimaryButton {
	var body: some View {
		Button(
			action: action,
			label: {
				Text(title)
					.foregroundColor(.app.white)
					.font(.app.body1Header)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
					.cornerRadius(8)
			}
		)
		.disabled(!isEnabled)
	}
}

// MARK: - PrimaryButton_Previews
struct PrimaryButton_Previews: PreviewProvider {
	static var previews: some View {
		PrimaryButton(
			title: "A title",
			action: {}
		)
	}
}
