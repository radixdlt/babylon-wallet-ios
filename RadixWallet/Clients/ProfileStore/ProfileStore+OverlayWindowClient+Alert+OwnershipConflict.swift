extension OverlayWindowClient.Item.AlertState {
	public static func profileUsedOnAnotherDeviceAlert(
		conflictingOwners: ConflictingOwners
	) -> Self {
		.init(
			title: { TextState(L10n.Splash.ProfileOnAnotherDeviceAlert.title) },
			actions: {
				ButtonState(
					role: .none,
					action: .claimAndContinueUseOnThisPhone,
					label: {
						TextState(L10n.Splash.ProfileOnAnotherDeviceAlert.claimExisting)
					}
				)
				ButtonState(
					role: .destructive,
					action: .deleteProfileFromThisPhone,
					label: {
						TextState(L10n.Splash.ProfileOnAnotherDeviceAlert.claimHere)
					}
				)
				ButtonState(
					role: .cancel,
					action: .dismissed,
					label: {
						TextState(L10n.Splash.ProfileOnAnotherDeviceAlert.askLater)
					}
				)
			},
			message: {
				TextState(overlayClientProfileStoreOwnershipConflictTextState)
			}
		)
	}
}

let overlayClientProfileStoreOwnershipConflictTextState = L10n.Splash.ProfileOnAnotherDeviceAlert.message

extension OverlayWindowClient.Item.AlertAction {
	static var claimAndContinueUseOnThisPhone: Self {
		.primaryButtonTapped
	}

	static var deleteProfileFromThisPhone: Self {
		.secondaryButtonTapped
	}
}
