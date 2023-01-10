import ComposableArchitecture
import Foundation
@testable import NewConnectionFeature
import P2PConnection
import SharedModels
import TestUtils

// MARK: - NewConnectionTests
@MainActor
final class NewConnectionTests: TestCase {
	func test__GIVEN__scanQR_screen__WHEN__secrets_are_scanned__THEN__we_start_connect_using_secrets() async throws {
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.scanQR(.init()),
			reducer: NewConnection()
		)
		let secrets = ConnectionSecrets.placeholder
		await store.send(.child(.scanQR(.delegate(.connectionSecretsFromScannedQR(secrets))))) {
			$0 = .connectUsingSecrets(.init(connectionSecrets: secrets))
		}
	}

	func test__GIVEN__connecting__WHEN__connected__THEN_we_delegate_to_parent_reducer() async throws {
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: .placeholder)
			),
			reducer: NewConnection()
		)
		let connectedClient = P2P.ClientWithConnectionStatus(p2pClient: .previewValue)
		await store.send(.child(.connectUsingSecrets(.delegate(.connected(connectedClient)))))
		await store.receive(.delegate(.newConnection(connectedClient)))
	}

	func test__GIVEN__new_connected_client__WHEN__user_dismisses_flow__THEN__connection_is_saved_but_without_name() async throws {
		let connectedClient = P2P.ClientWithConnectionStatus(p2pClient: .previewValue, connectionStatus: .connected)

		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(
					connectionSecrets: .placeholder,
					idOfNewConnection: connectedClient.id
				)
			),
			reducer: NewConnection()
		)

		await store.send(.internal(.view(.dismissButtonTapped)))
		await store.receive(.delegate(.newConnection(connectedClient)))
	}

	func test__GIVEN_new_connected_client__WHEN__user_confirms_name__THEN__connection_is_saved_with_that_name_trimmed() async throws {
		let secrets = ConnectionSecrets.placeholder

		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: secrets, idOfNewConnection: secrets.connectionID)
			),
			reducer: NewConnection()
		)
		let connectionName = "Foobar"
		await store.send(.child(.connectUsingSecrets(.view(.nameOfConnectionChanged(connectionName + " "))))) {
			$0 = .connectUsingSecrets(.init(
				connectionSecrets: secrets,
				idOfNewConnection: secrets.connectionID,
				nameOfConnection: connectionName + " ",
				isNameValid: true
			)
			)
		}

		let testScheduler = DispatchQueue.test
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		await store.send(.child(.connectUsingSecrets(.view(.confirmNameButtonTapped))))
		await testScheduler.advance(by: .seconds(1))
		let connectedClient = P2P.ClientWithConnectionStatus(p2pClient: .init(connectionPassword: secrets.connectionPassword, displayName: connectionName), connectionStatus: .connected)

		await store.receive(.child(.connectUsingSecrets(.delegate(.connected(connectedClient)))))
		await store.receive(.delegate(.newConnection(
			connectedClient
		))
		)
	}
}
