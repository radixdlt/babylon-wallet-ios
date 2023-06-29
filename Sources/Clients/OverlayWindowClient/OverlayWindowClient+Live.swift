import AsyncExtensions
import ComposableArchitecture
import Dependencies
import Prelude
import Resources
import SwiftUI

extension OverlayWindowClient: DependencyKey {
	public static let liveValue: Self = {
		let items = AsyncPassthroughSubject<Item>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.pasteboardClient) var pasteBoardClient

		errorQueue.errors().map { error in
			Item.alert(.init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				message: { TextState(error.localizedDescription) }
			))
		}.subscribe(items)

		pasteBoardClient.copyEvents().map { _ in
			Item.hud(.init(
				text: "Copied",
				icon: .system("checkmark.circle.fill"),
				iconForegroundColor: .app.green1
			))
		}.subscribe(items)

		return .init(
			scheduledItems: { items.eraseToAnyAsyncSequence() },
			scheduleAlert: { items.send(.alert($0)) },
			scheduleHUD: { items.send(.hud($0)) },
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			onAlertAction: { id in
				/// Fallback to `dismissed` action.
				await alertActions.first { $0.id == id }?.action ?? .dismissed
			}
		)
	}()
}
