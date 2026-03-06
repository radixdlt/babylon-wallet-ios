import ComposableArchitecture
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

@MainActor
final class SignalingServersSettingsFeatureTests: TestCase {
	func test_whenTaskLoadsProfiles_thenCurrentAndOthersAreSplit() async {
		let profiles = makeProfiles()
		let store = TestStore(
			initialState: SignalingServersSettings.State(),
			reducer: SignalingServersSettings.init
		) {
			$0.p2pTransportProfilesClient.p2pTransportProfilesValues = {
				AsyncLazySequence([profiles]).eraseToAnyAsyncSequence()
			}
		}

		let task = await store.send(.view(.task))
		await store.receive(.internal(.profilesLoaded(.success(profiles)))) {
			$0.current = profiles.current
			$0.others = profiles.all.filter { $0.signalingServer != profiles.current.signalingServer }
		}
		await task.cancel()
	}

	func test_whenAddButtonTapped_thenCreateDetailsIsPresented() async {
		let store = TestStore(
			initialState: SignalingServersSettings.State(),
			reducer: SignalingServersSettings.init
		)

		await store.send(.view(.addProfileButtonTapped)) {
			$0.destination = .details(.create)
		}
	}

	func test_whenRowTapped_thenEditDetailsIsPresented() async throws {
		let profiles = makeProfiles()
		let otherProfile = try XCTUnwrap(profiles.all.first(where: { $0.signalingServer != profiles.current.signalingServer }))
		let store = TestStore(
			initialState: SignalingServersSettings.State(
				current: profiles.current,
				others: profiles.all.filter { $0.signalingServer != profiles.current.signalingServer }
			),
			reducer: SignalingServersSettings.init
		)

		await store.send(.view(.rowTapped(otherProfile.signalingServer))) {
			$0.destination = .details(.edit(id: otherProfile.signalingServer))
		}
	}

	func test_whenCreateSaveHitsDuplicate_thenErrorIsShown() async {
		let store = TestStore(
			initialState: .create,
			reducer: SignalingServerDetails.init
		) {
			$0.p2pTransportProfilesClient.hasProfileWithSignalingServerURL = { _ in true }
		}
		store.exhaustivity = .off

		await store.send(.view(.nameChanged("Test Profile"))) {
			$0.name = "Test Profile"
			$0.saveButtonState = .disabled
		}
		await store.send(.view(.signalingServerChanged("wss://example.com"))) {
			$0.signalingServer = "wss://example.com"
			$0.saveButtonState = .enabled
		}
		await store.send(.view(.saveButtonTapped)) {
			$0.saveButtonState = .loading(.local)
		}
		await store.receive(.internal(.duplicateURLFound)) {
			$0.errorText = "A signaling server with this URL already exists."
			$0.saveButtonState = .enabled
		}
	}

	func test_whenEditSaveSucceeds_thenUpdatedProfileIsSubmitted() async throws {
		let profiles = makeProfiles()
		let updatedProfile = ActorIsolated<P2PTransportProfile?>(nil)
		let store = TestStore(
			initialState: .edit(id: profiles.current.signalingServer),
			reducer: SignalingServerDetails.init
		) {
			$0.p2pTransportProfilesClient.getProfiles = { profiles }
			$0.p2pTransportProfilesClient.updateProfile = { profile in
				await updatedProfile.setValue(profile)
				return true
			}
		}
		store.exhaustivity = .off

		await store.send(.view(.task))
		await store.receive(.internal(.profileLoaded(.success(.init(profile: profiles.current, isCurrent: true))))) {
			$0.originalProfile = profiles.current
			$0.isCurrent = true
			$0.name = profiles.current.name
			$0.signalingServer = profiles.current.signalingServer
			$0.stunURLs = .init(uniqueElements: profiles.current.stun.urls.map { .init(value: $0) })
			$0.turnURLs = .init(uniqueElements: profiles.current.turn.urls.map { .init(value: $0) })
			$0.turnUsername = profiles.current.turn.username ?? ""
			$0.turnCredential = profiles.current.turn.credential ?? ""
			$0.saveButtonState = .disabled
		}

		await store.send(.view(.turnUsernameChanged("updated-user"))) {
			$0.turnUsername = "updated-user"
			$0.saveButtonState = .enabled
		}
		await store.send(.view(.saveButtonTapped)) {
			$0.errorText = nil
			$0.saveButtonState = .loading(.local)
		}
		await store.receive(.internal(.saveResult(.success(true))))

		let profile = try await XCTUnwrap(updatedProfile.value)
		XCTAssertEqual(profile.signalingServer, profiles.current.signalingServer)
		XCTAssertEqual(profile.turn.username, "updated-user")
	}

	private func makeProfiles() -> SavedP2PTransportProfiles {
		.sample
	}
}
