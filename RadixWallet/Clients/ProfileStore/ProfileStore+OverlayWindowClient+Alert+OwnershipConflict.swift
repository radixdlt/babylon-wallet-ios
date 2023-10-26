extension OverlayWindowClient.Item.AlertState {
	public static func profileUsedOnAnotherDeviceAlert(
		conflictingOwners: ConflictingOwners
	) -> Self {
		.init(
			title: { TextState("Claim This Wallet?") }, // FIXME: Strings
			actions: {
				ButtonState(
					role: .none,
					action: .claimAndContinueUseOnThisPhone,
					label: {
						// FIXME: Strings
						TextState("Claim Existing Wallet")
					}
				)
				ButtonState(
					role: .destructive,
					action: .deleteProfileFromThisPhone,
					label: {
						// FIXME: Strings
						TextState("Clear Wallet on This Phone")
					}
				)
			},
			message: {
				overlayClientProfileStoreOwnershipConflictTextState
			}
		)
	}
}

let overlayClientProfileStoreOwnershipConflictTextState = TextState("This wallet is currently configured with a set of Accounts and Personas in use by a different phone.\n\nYou can claim this wallet for use on this phone instead, removing access by the other phone.\n\nOr you can clear this wallet from this phone and start fresh.") // FIXME: Strings

extension OverlayWindowClient.Item.AlertAction {
	static var claimAndContinueUseOnThisPhone: Self {
		.primaryButtonTapped
	}

	static var deleteProfileFromThisPhone: Self {
		.secondaryButtonTapped
	}
}
