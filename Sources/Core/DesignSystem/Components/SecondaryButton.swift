import SwiftUI

// MARK: - SecondaryButton
public struct SecondaryButton: View {
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

public extension SecondaryButton {
	var body: some View {
		Button(
			action: action,
			label: {
				Text(title)
					.foregroundColor(isEnabled ? Color.app.gray1 : Color.app.gray3)
					.font(.app.body1Header)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.background(Color.app.gray4)
					.cornerRadius(8)
			}
		)
		.disabled(!isEnabled)
	}
}

// MARK: - SecondaryButton_Previews
struct SecondaryButton_Previews: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return SecondaryButton(
			title: "Secondary button",
			isEnabled: true,
			action: {}
		)
	}
}
