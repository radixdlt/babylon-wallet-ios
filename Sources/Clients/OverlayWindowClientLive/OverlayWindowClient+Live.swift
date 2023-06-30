import AsyncExtensions
import ComposableArchitecture
import Dependencies
import DesignSystem
import OverlayWindowClient
import Prelude
import Resources

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
		}.subscribe(items)

		pasteBoardClient.copyEvents().map { _ in Item.hud(.copied) }.subscribe(items)

		return .init(
			scheduledItems: { items.eraseToAnyAsyncSequence() },
			scheduleAlert: { alert in
				items.send(.alert(alert))
				return await alertActions.first { $0.id == alert.id }?.action ?? .dismissed
			},
			scheduleHUD: { items.send(.hud($0)) },
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			setIsUserIteractionEnabled: { isUserInteractionEnabled.send($0) },
			isUserInteractionEnabled: { isUserInteractionEnabled.eraseToAnyAsyncSequence() }
		)
	}()
}
