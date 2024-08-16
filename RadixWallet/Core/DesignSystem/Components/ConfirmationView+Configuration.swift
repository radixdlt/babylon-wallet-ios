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
			title: L10n.AssetDetails.HideAsset.title,
			message: L10n.AssetDetails.HideAsset.message,
			primaryAction: L10n.AssetDetails.HideAsset.button
		)
	}
}
