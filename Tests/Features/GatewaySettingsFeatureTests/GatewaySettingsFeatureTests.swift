import FeatureTestingPrelude
@testable import GatewaySettingsFeature

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
		let allGateways: [Radix.Gateway] = [.nebunet, .hammunet, .enkinet, .mardunet]
		let currentGateway: Radix.Gateway = .nebunet
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings()
		) {
			$0.gatewaysClient.getAllGateways = {
				.init(rawValue: .init(uniqueElements: allGateways))!
			}
			$0.gatewaysClient.getCurrentGateway = {
				currentGateway
			}
		}

		// when
		await store.send(.view(.appeared))
		await store.receive(.internal(.presentGateways(all: allGateways, current: currentGateway))) {
			// then
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: allGateways.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: currentGateway.id == $0.id,
						canBeDeleted: $0.id != Radix.Gateway.nebunet.id
					)
				}
				.sorted(by: { !$0.canBeDeleted && $1.canBeDeleted })
			))

			$0.currentGateway = .nebunet
		}
	}

	func test_whenUserInputsURL_thenAddButtonChangesStateBasedOnURLValidity() async throws {
		// given
		let store = TestStore(
			initialState: AddNewGateway.State(),
			reducer: AddNewGateway()
		)
		let validURL = URL.previewValue.absoluteString

		// when
		await store.send(.view(.textFieldChanged(validURL))) {
			// then
			$0.inputtedURL = validURL
			$0.addGatewayButtonState = .enabled
		}

		// given
		let invalidURL = "non valid URL"

		// when
		await store.send(.view(.textFieldChanged(invalidURL))) {
			// then
			$0.inputtedURL = invalidURL
			$0.addGatewayButtonState = .disabled
		}
	}

	func test_whenTappedOnRemoveGateway_removeGatewayAlertIsShown() async throws {
		// given
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings()
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
			$0.removeGatewayAlert = .init(
				title: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.title) },
				actions: {
					ButtonState(role: .cancel, action: .cancelButtonTapped) {
						TextState(L10n.GatewaySettings.RemoveGatewayAlert.cancelButtonTitle)
					}
					ButtonState(action: .removeButtonTapped(gatewayToBeDeleted)) {
						TextState(L10n.GatewaySettings.RemoveGatewayAlert.removeButtonTitle)
					}
				},
				message: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.message) }
			)
		}
	}

	func test_whenNonCurrentGatewayRemovalIsConfirmed_removeGateway() async throws {
		// given
		let gatewayToBeDeleted = GatewayRow.State(gateway: .enkinet, isSelected: false, canBeDeleted: true)
		let allGateways: [Radix.Gateway] = [.nebunet, .hammunet, .enkinet, .mardunet]
		let gatewaysAfterDeletion: [Radix.Gateway] = [.nebunet, .hammunet, .mardunet]
		let currentGateway: Radix.Gateway = .nebunet

		var initialState = GatewaySettings.State()
		initialState.removeGatewayAlert = .init(
			title: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.title) },
			actions: {
				ButtonState(role: .cancel, action: .cancelButtonTapped) {
					TextState(L10n.GatewaySettings.RemoveGatewayAlert.cancelButtonTitle)
				}
				ButtonState(action: .removeButtonTapped(gatewayToBeDeleted)) {
					TextState(L10n.GatewaySettings.RemoveGatewayAlert.removeButtonTitle)
				}
			},
			message: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.message) }
		)
		initialState.currentGateway = currentGateway

		let removedGateway = ActorIsolated<Bool>(false)
		let store = TestStore(
			initialState: initialState,
			reducer: GatewaySettings()
		) {
			$0.gatewaysClient.removeGateway = { _ in
				await removedGateway.setValue(true)
			}
			$0.gatewaysClient.getAllGateways = {
				if await removedGateway.value == true {
					return .init(rawValue: .init(uniqueElements: gatewaysAfterDeletion))!
				} else {
					return .init(rawValue: .init(uniqueElements: allGateways))!
				}
			}
			$0.gatewaysClient.getCurrentGateway = {
				currentGateway
			}
			$0.continuousClock = TestClock()
		}
		store.exhaustivity = .off

		// when
		await store.send(.view(.appeared))

		// then
		await store.receive(.internal(.presentGateways(all: allGateways, current: currentGateway))) {
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: allGateways.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: currentGateway.id == $0.id,
						canBeDeleted: $0.id != Radix.Gateway.nebunet.id
					)
				}
				.sorted(by: { !$0.canBeDeleted && $1.canBeDeleted })
			))

			$0.currentGateway = .nebunet
		}

		// when
		await store.send(.view(.removeGateway(.presented(.removeButtonTapped(gatewayToBeDeleted))))) {
			// then
			$0.removeGatewayAlert = nil
		}
		await store.receive(.internal(.presentGateways(all: gatewaysAfterDeletion, current: currentGateway))) {
			$0.gatewayList = .init(gateways: .init(
				uniqueElements: gatewaysAfterDeletion.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: currentGateway.id == $0.id,
						canBeDeleted: $0.id != Radix.Gateway.nebunet.id
					)
				}
				.sorted(by: { !$0.canBeDeleted && $1.canBeDeleted })
			))

			$0.currentGateway = .nebunet
		}
	}

	func test_whenAddGatewayButtonIsTapped_thenPresentAddNewGatewayScreen() async throws {
		// given
		let store = TestStore(
			initialState: GatewaySettings.State(),
			reducer: GatewaySettings()
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
			reducer: AddNewGateway()
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
		await store.receive(.internal(.addGatewayResult(.success(.init()))))
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
