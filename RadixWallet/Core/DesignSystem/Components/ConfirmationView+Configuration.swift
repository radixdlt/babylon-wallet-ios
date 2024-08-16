import Foundation

extension ConfirmationView.Configuration {
	static var hideAccount: Self {
		.init(
			title: L10n.AccountSettings.HideAccount.title,
			message: L10n.AccountSettings.HideAccount.message,
			primaryAction: L10n.AccountSettings.HideAccount.button
		)
	}

	static var hideAsset: Self {
		.init(
			title: "Hide Asset",
			message: "Hide this asset in your Radix Wallet? You can always unhide it in your account settings.",
			primaryAction: "Hide Asset"
		)
	}
}
