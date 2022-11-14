import SwiftUI

// MARK: - PrimaryButton
public struct PrimaryButton: View {
	let title: String
	let isEnabled: Bool
	let role: ButtonRole?
	let action: () -> Void

	public init(
		title: String,
		role: ButtonRole? = nil,
		isEnabled: Bool = true,
		action: @escaping () -> Void
	) {
		self.title = title
		self.isEnabled = isEnabled
		self.action = action
		self.role = role
	}
}

public extension PrimaryButton {
	init(
		_ title: String,
		role: ButtonRole? = nil,
		isEnabled: Bool = true,
		action: @escaping () -> Void
	) {
		self.init(
			title: title,
			role: role,
			isEnabled: isEnabled,
			action: action
		)
	}
}

public extension PrimaryButton {
	var body: some View {
		Button(
			role: role,
			action: action,
			label: {
				Text(title)
					.font(.app.body1Header)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.if(role == nil) { label in
						label
							.foregroundColor(.app.white)
							.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
					}
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
