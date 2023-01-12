import FeaturePrelude
import ManageGatewayAPIEndpointsFeature
import Profile
import TestUtils

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
		let getNetworkAndGatewayCalled = ActorIsolated(false)
		let store = TestStore(
			// GIVEN initial state
			initialState: ManageGatewayAPIEndpoints.State(),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.getNetworkAndGateway = {
				await getNetworkAndGatewayCalled.setValue(true)
				return .previewValue
			}
		}
		store.exhaustivity = .off
		// WHEN view did appear
		await store.send(.internal(.view(.didAppear)))
		// THEN current network is loaded
		await store.receive(.internal(.system(.loadNetworkAndGatewayResult(.success(.previewValue)))))
		await getNetworkAndGatewayCalled.withValue {
			XCTAssertTrue($0)
		}
	}

	func test__GIVEN__current_network_and_gateway__WHEN__user_inputs_same_url__THEN__switchToButton_remains_disabled() async throws {
		// GIVEN a current network and gateway
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .previewValue
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentNetworkAndGateway: currentNetworkAndGateway,
				isSwitchToButtonEnabled: true // to capture state change
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off
		await store.send(.view(.urlStringChanged(
			// WHEN user inputs same url
			currentNetworkAndGateway.gatewayAPIEndpointURL.absoluteString
		))) {
			// THEN switchToButton is disabled
			$0.isSwitchToButtonEnabled = false
		}
	}

	func test__GIVEN__current_network_and_gateway__WHEN__user_inputs_a_valid_new_url__THEN__switchToButton_is_enabled() async throws {
		// GIVEN a current network and gateway
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .mardunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentNetworkAndGateway: currentNetworkAndGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off

		await store.send(.view(.urlStringChanged(
			// WHEN user inputs a valid NEW url
			AppPreferences.NetworkAndGateway.nebunet.gatewayAPIEndpointURL.absoluteString
		))) {
			// THEN switchToButton is enabled
			$0.isSwitchToButtonEnabled = true
		}
	}

	func test__GIVEN__switchToButton_is_enabled__WHEN__user_inputs_an_invalid_url__THEN__switchToButton_is_disabled() async throws {
		// GIVEN a current network and gateway
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .previewValue
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentNetworkAndGateway: currentNetworkAndGateway,
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
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .mardunet
		let newNetworkAndGateway: AppPreferences.NetworkAndGateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				urlString: newNetworkAndGateway.gatewayAPIEndpointURL.absoluteString,
				currentNetworkAndGateway: currentNetworkAndGateway,
				isSwitchToButtonEnabled: true
			),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.validateGatewayURL = {
				await validatedGatewayURL.setValue($0)
				return newNetworkAndGateway
			}
			$0.networkSwitchingClient.hasAccountOnNetwork = { _ in
				false
			}
		}
		store.exhaustivity = .off
		await store.send(.internal(.view(.switchToButtonTapped))) {
			$0.isValidatingEndpoint = true
		}
		await store.receive(.internal(.system(.gatewayValidationResult(.success(newNetworkAndGateway)))))
		await validatedGatewayURL.withValue {
			XCTAssertEqual($0, newNetworkAndGateway.gatewayAPIEndpointURL)
		}
	}

	func test__GIVEN__validating_a_new_endpoint__WHEN__its_validated__THEN__we_stop_loading_and_we_check_if_user_has_accounts_on_this_network() async throws {
		let hasAccountsOnNetwork = false
		let networkCheckedForAccounts = ActorIsolated<AppPreferences.NetworkAndGateway?>(nil)
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .mardunet
		let newNetworkAndGateway: AppPreferences.NetworkAndGateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentNetworkAndGateway: currentNetworkAndGateway,
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
		await store.send(.internal(.system(.gatewayValidationResult(.success(newNetworkAndGateway))))) {
			$0.isValidatingEndpoint = false
			$0.validatedNewNetworkAndGatewayToSwitchTo = newNetworkAndGateway
		}
		await store.receive(.internal(.system(.hasAccountsResult(.success(hasAccountsOnNetwork)))))
	}

	func test__GIVEN__no_existing_accounts_on_a_new_network__THEN__createAccount__is_displayed() async throws {
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .mardunet
		let newNetworkAndGateway: AppPreferences.NetworkAndGateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				currentNetworkAndGateway: currentNetworkAndGateway,
				validatedNewNetworkAndGatewayToSwitchTo: newNetworkAndGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .off
		await store.send(.internal(.system(.hasAccountsResult(.success(false)))))
		await store.receive(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newNetworkAndGateway)))) {
			$0.createAccountCoordinator = .init(
				completionDestination: .home,
				rootState: .init(
					onNetworkWithID: newNetworkAndGateway.network.id,
					isFirstAccount: true
				)
			)
		}
	}

	func test__GIVEN__finish_created_account_on_new_network__THEN__switchTo_is_called_on_networkSwitchingClient() async throws {
		let networkSwitchedTo = ActorIsolated<AppPreferences.NetworkAndGateway?>(nil)
		let currentNetworkAndGateway: AppPreferences.NetworkAndGateway = .mardunet
		let newNetworkAndGateway: AppPreferences.NetworkAndGateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				createAccountCoordinator: .init(
					completionDestination: .home,
					rootState: .init(
						onNetworkWithID: newNetworkAndGateway.network.id
					)
				),
				currentNetworkAndGateway: currentNetworkAndGateway,
				validatedNewNetworkAndGatewayToSwitchTo: newNetworkAndGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		) {
			$0.networkSwitchingClient.switchTo = {
				await networkSwitchedTo.setValue($0)
				return $0
			}
		}
		store.exhaustivity = .off
		await store.send(.createAccountCoordinator(.delegate(.completed))) {
			$0.createAccountCoordinator = nil
		}

		await store.receive(.internal(.system(.switchToResult(.success(newNetworkAndGateway)))))
		await networkSwitchedTo.withValue {
			XCTAssertEqual($0, newNetworkAndGateway)
		}
	}

	func test__GIVEN__apa__WHEN__createAccount_dismissed_during_network_switching__THEN__network_remains_unchanged() async throws {
		let newNetworkAndGateway: AppPreferences.NetworkAndGateway = .nebunet
		let store = TestStore(
			initialState: ManageGatewayAPIEndpoints.State(
				createAccountCoordinator: .init(
					completionDestination: .home,
					rootState: .init(
						onNetworkWithID: newNetworkAndGateway.network.id
					)
				),
				currentNetworkAndGateway: .mardunet,
				validatedNewNetworkAndGatewayToSwitchTo: newNetworkAndGateway
			),
			reducer: ManageGatewayAPIEndpoints()
		)
		store.exhaustivity = .on // we ensure `exhaustivity` is on, to assert nothing happens, i.e. `switchTo` is not called on networkSwitchingClient
		await store.send(.createAccountCoordinator(.delegate(.dismissed))) {
			$0.createAccountCoordinator = nil
			$0.validatedNewNetworkAndGatewayToSwitchTo = nil
		}
		// nothing else should happen
	}
}

import ProfileClient
#if DEBUG

public extension URL {
	static let previewValue = URL(string: "https://example.com")!
}

public extension Network {
	static let previewValue = Self(name: "Placeholder", id: .simulator)
}

public extension AppPreferences.NetworkAndGateway {
	static let previewValue = Self(
		network: .previewValue,
		gatewayAPIEndpointURL: .previewValue
	)
}
#endif // DEBUG
