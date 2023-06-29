import AsyncExtensions
import ComposableArchitecture
import Dependencies
import Prelude
import Resources
import SwiftUI
import UIKit

extension OverlayWindowClient: DependencyKey {
	public static let liveValue: Self = {
		let items = AsyncPassthroughSubject<Item>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()

		@Dependency(\.errorQueue) var errorQueue

		errorQueue.errors().map { error in
			Item.alert(.init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				message: { TextState(error.localizedDescription) }
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
