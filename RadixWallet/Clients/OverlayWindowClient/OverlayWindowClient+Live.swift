// MARK: - OverlayWindowClient + DependencyKey
extension OverlayWindowClient: DependencyKey {
	public static let liveValue: Self = {
		let items = AsyncPassthroughSubject<Item>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()
		let isUserInteractionEnabled = AsyncPassthroughSubject<Bool>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.pasteboardClient) var pasteBoardClient

		errorQueue.errors().map { error in
			Item.alert(.init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				message: { TextState(error.localizedDescription) }
			))
		}
		.subscribe(items)

		pasteBoardClient.copyEvents().map { _ in Item.hud(.copied) }.subscribe(items)

		let scheduleAlertIgnoreAction: ScheduleAlertIgnoreAction = { alert in
			items.send(.alert(alert))
		}

		return .init(
			scheduledItems: { items.eraseToAnyAsyncSequence() },
			scheduleAlertIgnoreAction: scheduleAlertIgnoreAction,
			scheduleAlertAwaitAction: { alert in
				scheduleAlertIgnoreAction(alert)
				return await alertActions.first { $0.id == alert.id }?.action ?? .dismissed
			},
			scheduleHUD: { items.send(.hud($0)) },
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			setIsUserIteractionEnabled: { isUserInteractionEnabled.send($0) },
			isUserInteractionEnabled: { isUserInteractionEnabled.eraseToAnyAsyncSequence() },
			scheduleLinkingDapp: { dAppMetdata in
				let id = UUID()
				items.send(.autodismissSheet(id, dAppMetdata))
				// FIXME: Should not be alert actions
				return await alertActions.first { $0.id == id }?.action ?? .dismissed
			}
		)
	}()
}

extension OverlayWindowClient.Item.HUD {
	public static let updatedAccount = Self(text: L10n.AccountSettings.updatedAccountHUDMessage)
	public static let copied = Self(text: L10n.AddressAction.copiedToClipboard)
	public static let seedPhraseImported = Self(text: L10n.ImportMnemonic.seedPhraseImported)
	public static let thankYou = Self(text: "Thank you!")
}
