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
			isUserInteractionEnabled: { isUserInteractionEnabled.eraseToAnyAsyncSequence() }
		)
	}()
}

extension OverlayWindowClient.Item.HUD {
	fileprivate static let copied = Self(text: L10n.AddressAction.copiedToClipboard)
}
