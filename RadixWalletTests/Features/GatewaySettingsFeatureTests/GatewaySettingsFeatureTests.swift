@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - GatewaySettingsFeatureTests
@MainActor
final class GatewaySettingsFeatureTests: TestCase {
	func test_dns_with_port() throws {
		let url = try XCTUnwrap(URL(string: "https://example.with.ports.com:12345"))
		XCTAssertEqual(url.port, 12345)
	}

	func test_ip_with_port() throws {
		let url = try XCTUnwrap(URL(string: "https://12.34.56.78:12345"))
		XCTAssertEqual(url.port, 12345)
	}

	func test_whenViewAppeared_thenCurrentGatewayAndGatewayListIsLoaded() async throws {
		// given
		let otherGateways: Gateways = [.stokenet, .ansharnet]
		let currentGateway: Gateway = .mainnet
		let savedGateways = try! SavedGateways(
			current: currentGateway,
			other: otherGateways.elements
		)

		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings.init
		) {
			$0.gatewaysClient.getAllGateways = {
				otherGateways
			}
			$0.gatewaysClient.gatewaysValues = { AsyncLazySequence([
				try! .init(current: currentGateway, other: otherGateways.elements),
			]
			).eraseToAnyAsyncSequence() }
		}

		// when
		let viewTask = await store.send(.view(.task))
		await store.receive(.internal(.savedGatewaysLoadedResult(.success(savedGateways)))) {
			// then
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: savedGateways.all.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: savedGateways.current.id == $0.id,
						canBeDeleted: !$0.isWellknown
					)
				}
			))

			$0.currentGateway = .mainnet
		}
		await viewTask.cancel()
	}

	func test_whenTappedOnRemoveGateway_removeGatewayAlertIsShown() async throws {
		// given
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings.init
		) {
			$0.errorQueue.schedule = { _ in }
		}
		store.exhaustivity = .off
		let gatewayToBeDeleted = GatewayRow.State(
			gateway: .sample,
			isSelected: false,
			canBeDeleted: true
		)

		// when
		await store.send(.child(.gatewayList(.delegate(.removeGateway(gatewayToBeDeleted))))) {
			// then
			$0.destination = .removeGateway(.removeGateway(row: gatewayToBeDeleted))
		}
	}

	func test_whenNonCurrentGatewayRemovalIsConfirmed_removeGateway() async throws {
		// given
		let gatewayToBeDeleted = GatewayRow.State(
			gateway: .ansharnet,
			isSelected: false,
			canBeDeleted: true
		)
		let otherGateways: Gateways = [.stokenet, .ansharnet]
		let currentGateway: Gateway = .mainnet
		let otherAfterDeletion: Gateways = [.stokenet]
		let savedGateways = try! SavedGateways(
			current: currentGateway,
			other: otherGateways.elements
		)
		let gatewaysAfterDeletion = try! SavedGateways(
			current: currentGateway,
			other: otherAfterDeletion.elements
		)

		var initialState = GatewaySettings.State()
		initialState.destination = .removeGateway(.removeGateway(row: gatewayToBeDeleted))
		initialState.currentGateway = currentGateway
		initialState.gatewayList = .init(gateways: .init(
			uniqueElements: savedGateways.all.map {
				GatewayRow.State(
					gateway: $0,
					isSelected: savedGateways.current.id == $0.id,
					canBeDeleted: !$0.isWellknown
				)
			}
		))

		let isGatewayRemoved = ActorIsolated<Bool>(false)
		let store = TestStore(
			initialState: initialState,
			reducer: GatewaySettings.init
		) {
			$0.gatewaysClient.removeGateway = { _ in
				await isGatewayRemoved.setValue(true)
			}
			$0.gatewaysClient.getAllGateways = {
				if await isGatewayRemoved.value == true {
					otherAfterDeletion
				} else {
					otherGateways
				}
			}
			$0.gatewaysClient.gatewaysValues = {
				let gateways = await isGatewayRemoved.value ? otherAfterDeletion : otherGateways
				return AsyncLazySequence([
					try! .init(current: currentGateway, other: gateways.elements),
				]).eraseToAnyAsyncSequence()
			}

			$0.continuousClock = TestClock()
		}
		store.exhaustivity = .off

		// when
		await store.send(.destination(.presented(.removeGateway(.removeButtonTapped(gatewayToBeDeleted))))) {
			// then
			$0.destination = nil
		}

		// when
		await store.send(.internal(.savedGatewaysLoadedResult(.success(gatewaysAfterDeletion)))) {
			// then
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: gatewaysAfterDeletion.all.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: gatewaysAfterDeletion.current.id == $0.id,
						canBeDeleted: !$0.isWellknown
					)
				}
			))

			$0.currentGateway = .mainnet
		}
	}

	func test_whenAddGatewayButtonIsTapped_thenPresentAddNewGatewayScreen() async throws {
		// given
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings.init
		)
		store.exhaustivity = .off

		// when
		await store.send(.view(.addGatewayButtonTapped)) {
			// then
			$0.destination = .addNewGateway(AddNewGateway.State())
		}
	}

	func test_whenNewAddGatewayButtonIsTapped_thenDelegateIsCalled() async throws {
		// given
		let allGateways: Gateways = [.nebunet, .hammunet, .enkinet, .mardunet]
		let validURL = URL.previewValue.absoluteString
		var initialState = AddNewGateway.State()
		initialState.inputtedURL = validURL

		let store = TestStore(
			initialState: initialState,
			reducer: AddNewGateway.init
		) {
			$0.networkSwitchingClient.validateGatewayURL = { _ in .sample }
			$0.gatewaysClient.addGateway = { _ in }
			$0.gatewaysClient.getAllGateways = {
				allGateways
			}
			$0.gatewaysClient.hasGateway = { _ in false }
		}
		store.exhaustivity = .off

		// when
		await store.send(.view(.addNewGatewayButtonTapped))
		await store.receive(.internal(.gatewayValidationResult(.success(.sample))))
		await store.receive(.internal(.addGatewayResult(.success(.instance))))
		await store.receive(.delegate(.dismiss))
	}

	func test_whenNewAddGatewayButtonIsTapped_duplicateGatewayIsRejected() async throws {
		// given
		let allGateways: Gateways = [.nebunet, .hammunet, .enkinet, .mardunet]
		let validURL = URL.previewValue.absoluteString
		var initialState = AddNewGateway.State()
		initialState.inputtedURL = validURL

		let store = TestStore(
			initialState: initialState,
			reducer: AddNewGateway.init
		) {
			$0.networkSwitchingClient.validateGatewayURL = { _ in .sample }
			$0.gatewaysClient.addGateway = { _ in }
			$0.gatewaysClient.getAllGateways = {
				allGateways
			}
			$0.gatewaysClient.hasGateway = { _ in true }
		}
		store.exhaustivity = .off

		// when
		await store.send(.view(.addNewGatewayButtonTapped))
		await store.receive(.internal(.showDuplicateURLError))
	}
}

#if DEBUG

extension URL {
	public static let previewValue = URL(string: "https://example.com")!
}
#endif // DEBUG
