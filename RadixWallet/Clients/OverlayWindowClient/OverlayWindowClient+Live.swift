// MARK: - OverlayWindowClient + DependencyKey
extension OverlayWindowClient: DependencyKey {
	public static let liveValue: Self = {
		let items = AsyncPassthroughSubject<Item>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()
		let fullScreenActions = AsyncPassthroughSubject<(action: FullScreenAction, id: FullScreenID)>()
		let isUserInteractionEnabled = AsyncPassthroughSubject<Bool>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.pasteboardClient) var pasteBoardClient

		errorQueue.errors().map { error in
			if let sargonError = error as? SargonError {
				#if DEBUG
				let message = error.localizedDescription
				#else
				let message = L10n.Error.emailSupportMessage(sargonError.errorCode)
				#endif
				return Item.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					actions: {
						ButtonState(role: .cancel, action: .dismissed) {
							TextState(L10n.Common.cancel)
						}
						ButtonState(action: .emailSupport(additionalInfo: error.localizedDescription)) { TextState(L10n.Error.emailSupportButtonTitle)
						}
					},
					message: { TextState(message) }
				))
			} else {
				return Item.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					message: { TextState(error.localizedDescription) }
				))
			}
		}
		.subscribe(items)

		pasteBoardClient.copyEvents().map { _ in Item.hud(.copied) }.subscribe(items)

		let scheduleAlertAndIgnoreAction: ScheduleAlertAndIgnoreAction = { alert in
			items.send(.alert(alert))
		}

		return .init(
			scheduledItems: { items.eraseToAnyAsyncSequence() },
			scheduleAlert: { alert in
				scheduleAlertAndIgnoreAction(alert)
				return await alertActions.first { $0.id == alert.id }?.action ?? .dismissed
			},
			scheduleAlertAndIgnoreAction: scheduleAlertAndIgnoreAction,
			scheduleHUD: { items.send(.hud($0)) },
			scheduleSheet: { items.send(.sheet($0)) },
			scheduleFullScreen: { fullScreen in
				items.send(.fullScreen(fullScreen))
				return await fullScreenActions.first { $0.id == fullScreen.id }?.action ?? .dismiss
			},
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			sendFullScreenAction: { action, id in fullScreenActions.send((action, id)) },
			setIsUserIteractionEnabled: { isUserInteractionEnabled.send($0) },
			isUserInteractionEnabled: { isUserInteractionEnabled.eraseToAnyAsyncSequence() }
		)
	}()
}

extension OverlayWindowClient {
	public func showInfoLink(_ state: InfoLinkSheet.State) {
		scheduleSheet(.infoLink(state))
	}
}

extension OverlayWindowClient.Item.HUD {
	public static let updatedAccount = Self(text: L10n.AccountSettings.updatedAccountHUDMessage)
	public static let copied = Self(text: L10n.AddressAction.copiedToClipboard)
	public static let seedPhraseImported = Self(text: L10n.ImportMnemonic.seedPhraseImported)
	public static let thankYou = Self(text: "Thank you!")
}
