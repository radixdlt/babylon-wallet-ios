import FeaturePrelude

extension View {
	public func shieldPromptView(
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
		.background(.app.whiteTransparent2)
		.cornerRadius(.small2)
		.onTapGesture {
			onTapGesture()
		}
	}

	public func importMnemonicPromptView(action: @escaping () -> Void) -> some View {
		shieldPromptView(
			text: "Recovery of seed phrase required", // FIXME: Strings
			action: action
		)
	}

	public func backupMnemonicPromptView(action: @escaping () -> Void) -> some View {
		shieldPromptView(
			text: "Back up this Account's seed phrase", // FIXME: Strings
			action: action
		)
	}
}
