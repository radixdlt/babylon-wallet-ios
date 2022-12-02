import Common
import DesignSystem
import SwiftUI

// MARK: - Row
struct Row: View {
	let title: String
	let action: () -> Void

	init(
		_ title: String,
		action: @escaping () -> Void
	) {
		self.title = title
		self.action = action
	}
}

extension Row {
	var body: some View {
		Button(
			action: {
				action()
			}, label: {
				ZStack {
					HStack {
						// TODO: replace appropriate settings icon when ready
						Rectangle()
							.frame(.verySmall)
							.foregroundColor(.app.gray4)
							.cornerRadius(.small3)

						Spacer()
							.frame(width: 20)

						Text(title)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						Spacer()

						Image(asset: AssetResource.chevronRight)
					}

					VStack {
						Spacer()
						Separator()
					}
				}
				.padding(.horizontal, .medium1)
				.foregroundColor(.app.gray1)
				.frame(height: .largeButtonHeight)
			}
		)
		.buttonStyle(SettingsRowStyle())
	}
}

// MARK: - SettingsRowStyle
struct SettingsRowStyle: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.background(configuration.isPressed ? Color.app.gray4 : Color.app.white)
	}
}

// MARK: - Row_Previews
struct Row_Previews: PreviewProvider {
	static var previews: some View {
		Row("Title", action: {})
	}
}
