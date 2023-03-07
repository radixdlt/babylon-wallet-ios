import FeatureTestingPrelude
import ManageGatewayAPIEndpointsFeature

// MARK: - ManageGatewayAPIEndpointsFeatureTests
@MainActor
final class ManageGatewayAPIEndpointsFeatureTests: TestCase {
	func test_dns_with_port() throws {
		let url = try XCTUnwrap(URL(string: "https://example.with.ports.com:12345"))
		XCTAssertEqual(url.port, 12345)
	}

	func test_ip_with_port() throws {
		let url = try XCTUnwrap(URL(string: "https://12.34.56.78:12345"))
		XCTAssertEqual(url.port, 12345)
	}

	//    func test__GIVEN__intialState__WHEN__an_invalid__URL

	func test__GIVEN__initialState__WHEN__view_did_appear__THEN__current_networkAndGateway_is_loaded() async throws {
		let getGatewayCalled = ActorIsolated(false)
		let store = TestStore(
			// GIVEN initial state
			initialState: ManageGatewayAPIEndpoints.State(),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.getCurrentGateway = {
				await getGatewayCalled.setValue(true)
				return .previewValue
			}
		}
		store.exhaustivity = .off
		// WHEN view did appear
		await store.send(.internal(.view(.didAppear)))
		// THEN current network is loaded
		await store.receive(.internal(.system(.loadGatewayResult(.success(.previewValue)))))
		await getGatewayCalled.withValue {
			XCTAssertTrue($0)
		}
	}

	func test__GIVEN__current_network_and_gateway__WHEN__user_inputs_same_url__THEN__switchToButton_remains_disabled() async throws {
		// GIVEN a current network and gateway
		let currentGateway: Gateway = .previewValue
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: currentGateway,
				isSwitchToButtonEnabled: true // to capture state change
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off
		await store.send(.view(.urlStringChanged(
			// WHEN user inputs same url
			currentGateway.url.absoluteString
		))) {
			// THEN switchToButton is disabled
			$0.isSwitchToButtonEnabled = false
		}
	}

	func test__GIVEN__current_network_and_gateway__WHEN__user_inputs_a_valid_new_url__THEN__switchToButton_is_enabled() async throws {
		// GIVEN a current network and gateway
		let currentGateway: Gateway = .mardunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: currentGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off

		await store.send(.view(.urlStringChanged(
			// WHEN user inputs a valid NEW url
			Gateway.nebunet.url.absoluteString
		))) {
			// THEN switchToButton is enabled
			$0.isSwitchToButtonEnabled = true
		}
	}

	func test__GIVEN__switchToButton_is_enabled__WHEN__user_inputs_an_invalid_url__THEN__switchToButton_is_disabled() async throws {
		// GIVEN a current network and gateway
		let currentGateway: Gateway = .previewValue
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: currentGateway,
				isSwitchToButtonEnabled: true // to capture state change
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off

		await store.send(.view(.urlStringChanged(
			// WHEN user inputs an invalid url
			"🧌"
		))) {
			// THEN switchToButton is disabled
			$0.isSwitchToButtonEnabled = false
		}
	}

	func test__GIVEN__swithToButton_enabled__WHEN__switchToButton_is_tapped__THEN__the_url_gets_validated() async throws {
		// GIVEN a current network and gateway
		let validatedGatewayURL = ActorIsolated<URL?>(nil)
		let currentGateway: Gateway = .mardunet
		let newGateway: Gateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				urlString: newGateway.url.absoluteString,
				currentGateway: currentGateway,
				isSwitchToButtonEnabled: true
			),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.validateGatewayURL = {
				await validatedGatewayURL.setValue($0)
				return newGateway
			}
			$0.networkSwitchingClient.hasAccountOnNetwork = { _ in
				false
			}
		}
		store.exhaustivity = .off
		await store.send(.internal(.view(.switchToButtonTapped))) {
			$0.isValidatingEndpoint = true
		}
		await store.receive(.internal(.system(.gatewayValidationResult(.success(newGateway)))))
		await validatedGatewayURL.withValue {
			XCTAssertEqual($0, newGateway.url)
		}
	}

	func test__GIVEN__validating_a_new_endpoint__WHEN__its_validated__THEN__we_stop_loading_and_we_check_if_user_has_accounts_on_this_network() async throws {
		let hasAccountsOnNetwork = false
		let networkCheckedForAccounts = ActorIsolated<Gateway?>(nil)
		let currentGateway: Gateway = .mardunet
		let newGateway: Gateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: currentGateway,
				isValidatingEndpoint: true
			),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.hasAccountOnNetwork = {
				await networkCheckedForAccounts.setValue($0)
				return hasAccountsOnNetwork
			}
		}
		store.exhaustivity = .off
		await store.send(.internal(.system(.gatewayValidationResult(.success(newGateway))))) {
			$0.isValidatingEndpoint = false
			$0.validatedNewGatewayToSwitchTo = newGateway
		}
		await store.receive(.internal(.system(.hasAccountsResult(.success(hasAccountsOnNetwork)))))
	}

	func test__GIVEN__no_existing_accounts_on_a_new_network__THEN__display_createAccount__flow() async throws {
		let networkSwitchedTo = ActorIsolated<Gateway?>(nil)
		let currentGateway: Gateway = .mardunet
		let newGateway: Gateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: currentGateway,
				validatedNewGatewayToSwitchTo: newGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.switchTo = {
				await networkSwitchedTo.setValue($0)
				return $0
			}
		}
		store.exhaustivity = .off
		// FIXME: tests should never send internal actions into the store. they should only send view or child actions.
		await store.send(.internal(.system(.hasAccountsResult(.success(false)))))
		await store.receive(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newGateway)))) {
			$0.destination = .createAccount(
				.init(config: .init(
					purpose: .firstAccountOnNewNetwork(newGateway.network.id)
				))
			)
		}
		await store.send(.child(.destination(.presented(.createAccount(.delegate(.completed)))))) {
			$0.destination = nil
		}
		await store.receive(.internal(.system(.switchToResult(.success(newGateway)))))
		await networkSwitchedTo.withValue {
			XCTAssertEqual($0, newGateway)
		}
	}

	func test__GIVEN__apa__WHEN__createAccount_dismissed_during_network_switching__THEN__network_remains_unchanged() async throws {
		let newGateway: Gateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentGateway: .mardunet,
				validatedNewGatewayToSwitchTo: newGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .on // we ensure `exhaustivity` is on, to assert nothing happens, i.e. `switchTo` is not called on networkSwitchingClient
		// FIXME: tests should never send internal actions into the store. they should only send view or child actions.
		await store.send(.internal(.system(.hasAccountsResult(.success(false)))))
		await store.receive(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newGateway)))) {
			$0.destination = .createAccount(
				.init(config: .init(
					purpose: .firstAccountOnNewNetwork(newGateway.network.id)
				))
			)
		}
		await store.send(.child(.destination(.presented(.createAccount(.delegate(.dismiss)))))) {
			$0.destination = nil
			$0.validatedNewGatewayToSwitchTo = nil
		}
		await store.finish() // nothing else should happen
	}
}

#if DEBUG

extension URL {
	public static let previewValue = URL(string: "https://example.com")!
}

extension Network {
	public static let previewValue = Self(name: "Placeholder", id: .simulator)
}

extension Gateway {
	public static let previewValue = Self(
		network: .previewValue,
		url: .previewValue
	)
}
#endif // DEBUG
