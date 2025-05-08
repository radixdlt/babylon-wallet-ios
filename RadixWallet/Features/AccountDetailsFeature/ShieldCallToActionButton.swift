import ComposableArchitecture
import SwiftUI

extension View {
	func shieldPromptView(
		text: String,
		action onTapGesture: @escaping () -> Void
	) -> some View {
		HStack {
			Image(asset: AssetResource.homeAccountSecurity)

			Text(text)
				.foregroundColor(.white)
				.textStyle(.body2HighImportance)

			Spacer()

			Circle()
				.fill()
				.foregroundColor(.red)
				.frame(width: .small2, height: .small2)
		}
		.padding(.small2)
		.background(.backgroundTransparent)
		.cornerRadius(.small2)
		.onTapGesture {
			onTapGesture()
		}
	}

	func importMnemonicPromptView(action: @escaping () -> Void) -> some View {
		shieldPromptView(
			text: L10n.ImportMnemonic.ShieldPrompt.enterSeedPhrase,
			action: action
		)
	}

	func exportMnemonicPromptView(action: @escaping () -> Void) -> some View {
		shieldPromptView(
			text: L10n.ImportMnemonic.ShieldPrompt.backupSeedPhrase,
			action: action
		)
	}
}
