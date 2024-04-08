@testable import Radix_Wallet_Dev
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
		let otherGateways: IdentifiedArrayOf<Radix.Gateway> = [.stokenet, .rcnet].asIdentifiable()
		let currentGateway: Radix.Gateway = .mainnet
		let gateways = try! Gateways(
			current: currentGateway,
			other: otherGateways
		)
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings.init
		) {
			$0.gatewaysClient.getAllGateways = {
				.init(rawValue: otherGateways)!
			}
			$0.gatewaysClient.gatewaysValues = { AsyncLazySequence([
				try! .init(current: currentGateway, other: otherGateways),
			]
			).eraseToAnyAsyncSequence() }
		}

		// when
		let viewTask = await store.send(.view(.task))
		await store.receive(.internal(.gatewaysLoadedResult(.success(gateways)))) {
			// then
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: gateways.all.elements.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: gateways.current.id == $0.id,
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
			gateway: .previewValue,
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
		let gatewayToBeDeleted = GatewayRow.State(gateway: .rcnet, isSelected: false, canBeDeleted: true)
		let otherGateways: IdentifiedArrayOf<Radix.Gateway> = [.stokenet, .rcnet].asIdentifiable()
		let currentGateway: Radix.Gateway = .mainnet
		let otherAfterDeletion: IdentifiedArrayOf<Radix.Gateway> = [.stokenet].asIdentifiable()
		let gateways = try! Gateways(
			current: currentGateway,
			other: otherGateways
		)
		let gatewaysAfterDeletion = try! Gateways(
			current: currentGateway,
			other: otherAfterDeletion
		)

		var initialState = GatewaySettings.State()
		initialState.destination = .removeGateway(.removeGateway(row: gatewayToBeDeleted))
		initialState.currentGateway = currentGateway
		initialState.gatewayList = .init(gateways: .init(
			uniqueElements: gateways.all.elements.map {
				GatewayRow.State(
					gateway: $0,
					isSelected: gateways.current.id == $0.id,
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
					.init(rawValue: .init(uniqueElements: otherAfterDeletion))!
				} else {
					.init(rawValue: .init(uniqueElements: otherGateways))!
				}
			}
			$0.gatewaysClient.gatewaysValues = {
				let gateways = await isGatewayRemoved.value ? otherAfterDeletion : otherGateways
				return AsyncLazySequence([
					try! .init(current: currentGateway, other: .init(uniqueElements: gateways)),
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
		await store.send(.internal(.gatewaysLoadedResult(.success(gatewaysAfterDeletion)))) {
			// then
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: gatewaysAfterDeletion.all.elements.map {
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
		let allGateways: [Radix.Gateway] = [.nebunet, .hammunet, .enkinet, .mardunet]
		let validURL = URL.previewValue.absoluteString
		var initialState = AddNewGateway.State()
		initialState.inputtedURL = validURL

		let store = TestStore(
			initialState: initialState,
			reducer: AddNewGateway.init
		) {
			$0.networkSwitchingClient.validateGatewayURL = { _ in .previewValue }
			$0.gatewaysClient.addGateway = { _ in }
			$0.gatewaysClient.getAllGateways = {
				.init(rawValue: .init(uniqueElements: allGateways))!
			}
		}
		store.exhaustivity = .off

		// when
		await store.send(.view(.addNewGatewayButtonTapped))
		await store.receive(.internal(.gatewayValidationResult(.success(.previewValue))))
		await store.receive(.internal(.addGatewayResult(.success(.instance))))
		await store.receive(.delegate(.dismiss))
	}
}

#if DEBUG

extension URL {
	public static let previewValue = URL(string: "https://example.com")!
}

extension Radix.Network {
	public static let previewValue = Self(
		name: "Placeholder",
		id: .simulator,
		displayDescription: "A placeholder description"
	)
}

extension Radix.Gateway {
	public static let previewValue = Self(
		network: .previewValue,
		url: .previewValue
	)
}
#endif // DEBUG
