@testable import Radix_Wallet_Dev
import XCTest

// MARK: - AccountAndPersonaHidingTests
@MainActor
final class AccountAndPersonaHidingTests: TestCase {
	func test_unhideAll_happyflow() async throws {
		let counts = EntitiesVisibilityClient.HiddenEntityCounts(hiddenAccountsCount: 5, hiddenPersonasCount: 4)

		let store = TestStore(
			initialState: AccountAndPersonaHiding.State(),
			reducer: AccountAndPersonaHiding.init
		)

		store.dependencies.entitiesVisibilityClient.getHiddenEntityCounts = {
			counts
		}

		let unhideAllEntitiesExpectation = expectation(description: "Waiting to unhide all entities")
		store.dependencies.entitiesVisibilityClient.unhideAllEntities = {
			unhideAllEntitiesExpectation.fulfill()
		}

		let scheduleCompletionHUD = ActorIsolated<OverlayWindowClient.Item.HUD?>(nil)
		store.dependencies.overlayWindowClient.scheduleHUD = { hud in
			Task {
				await scheduleCompletionHUD.setValue(hud)
			}
		}

		await store.send(.view(.task))

		await store.receive(.internal(.hiddenEntityCountsLoaded(counts))) {
			$0.hiddenEntityCounts = counts
		}

		await store.send(.view(.unhideAllTapped)) {
			$0.confirmUnhideAllAlert = .init(
				title: .init(L10n.AppSettings.EntityHiding.unhideAllSection),
				message: .init(L10n.AppSettings.EntityHiding.unhideAllConfirmation),
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				]
			)
		}

		await store.send(.view(.confirmUnhideAllAlert(.presented(.confirmTapped)))) {
			$0.confirmUnhideAllAlert = nil
		}

		wait(for: [unhideAllEntitiesExpectation], timeout: 1.0)

		let scheduledCompletionHUD = await scheduleCompletionHUD.value
		XCTAssertEqual(scheduledCompletionHUD, .updated)

		await store.receive(.internal(.didUnhideAllEntities)) {
			$0.hiddenEntityCounts = .init(hiddenAccountsCount: 0, hiddenPersonasCount: 0)
		}
	}

	func test_unhideAll_failedToUnhide_stateRemainsUnchanged() async throws {
		let counts = EntitiesVisibilityClient.HiddenEntityCounts(hiddenAccountsCount: 5, hiddenPersonasCount: 4)

		let store = TestStore(
			initialState: AccountAndPersonaHiding.State(),
			reducer: AccountAndPersonaHiding.init
		)

		store.dependencies.entitiesVisibilityClient.getHiddenEntityCounts = {
			counts
		}

		store.dependencies.entitiesVisibilityClient.unhideAllEntities = {
			throw NSError.anyError
		}

		let scheduleErrorExpectation = expectation(description: "Wait for Error is to bescheduled")
		store.dependencies.errorQueue.schedule = { _ in
			scheduleErrorExpectation.fulfill()
		}

		await store.send(.view(.task))

		await store.receive(.internal(.hiddenEntityCountsLoaded(counts))) {
			$0.hiddenEntityCounts = counts
		}

		await store.send(.view(.unhideAllTapped)) {
			$0.confirmUnhideAllAlert = .init(
				title: .init(L10n.AppSettings.EntityHiding.unhideAllSection),
				message: .init(L10n.AppSettings.EntityHiding.unhideAllConfirmation),
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				]
			)
		}

		await store.send(.view(.confirmUnhideAllAlert(.presented(.confirmTapped)))) {
			$0.confirmUnhideAllAlert = nil
		}

		wait(for: [scheduleErrorExpectation], timeout: 1.0)
	}
}

extension NSError {
	static let anyError = NSError(domain: "test", code: 1)
}
