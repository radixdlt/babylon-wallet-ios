import FeaturePrelude

// MARK: - SettingsRowStyle

extension ButtonStyle where Self == SettingsRowStyle {
	static var settingsRowStyle: SettingsRowStyle { SettingsRowStyle() }
}

// MARK: - SettingsRowStyle
struct SettingsRowStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.background(configuration.isPressed ? .app.gray4 : .app.white)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct SettingsRowStyle_Previews: PreviewProvider {
	static var previews: some View {
		PlainListRow(title: "Title") {} icon: {
			Image(systemName: "wallet.pass")
		}
		.buttonStyle(.settingsRowStyle)
	}
}
#endif
