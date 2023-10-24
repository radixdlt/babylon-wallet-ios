extension OverlayWindowClient.Item.AlertState {
	public static func profileUsedOnAnotherDeviceAlert(
		conflictingOwners: ConflictingOwners
	) -> Self {
		let keepUsingThisPhone = "Keen using this phone"
		let deleteOnThisPhone = "Delete on this phone"
		return .init(
			title: { TextState("Use one iPhone only.") }, // FIXME: Strings
			actions: {
				ButtonState(
					role: .none,
					action: .claimAndContinueUseOnThisPhone,
					label: {
						// FIXME: Strings
						TextState(keepUsingThisPhone)
					}
				)
				ButtonState(
					role: .destructive,
					action: .deleteProfileFromThisPhone,
					label: {
						// FIXME: Strings
						TextState(deleteOnThisPhone)
					}
				)
			},
			message: {
				// FIXME: Strings,
				TextState("It seems you have used the wallet on another iPhone, this is not supported.\n\nIf you select '\(keepUsingThisPhone)', you will see this warning if you start the app on the other phone.\n\nIf you select '\(deleteOnThisPhone)' the wallet data will be deleted on this phone and you can continue on the other phone.")
			}
		)
	}
}

extension OverlayWindowClient.Item.AlertAction {
	static var claimAndContinueUseOnThisPhone: Self {
		.primaryButtonTapped
	}

	static var deleteProfileFromThisPhone: Self {
		.secondaryButtonTapped
	}
}
