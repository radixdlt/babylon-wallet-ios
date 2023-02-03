import SwiftUI
import Resources

// MARK: - Row
public struct PlainListRow: View {
	let title: String
	let icon: Image
	let action: () -> Void
	
	public init(
		_ title: String,
		icon: Image,
		action: @escaping () -> Void
	) {
		self.title = title
		self.icon = icon
		self.action = action
	}
}

extension PlainListRow {
	public var body: some View {
		Button(
			action: {
				action()
			}, label: {
				ZStack {
					HStack {
						icon
							.frame(.verySmall)
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
//		.buttonStyle(SettingsRowStyle())
	}
}
