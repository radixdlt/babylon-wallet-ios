import ComposableArchitecture
import Converse
import ConverseCommon
import Foundation
@testable import NewConnectionFeature
import SharedModels
import TestUtils

@MainActor
final class NewConnectionTests: TestCase {
	func test__GIVEN__scanQR_screen__WHEN__secrets_are_scanned__THEN__we_start_connect_using_secrets() async throws {
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State(),
			reducer: NewConnection()
		)
		let secrets = ConnectionSecrets.placeholder
		await store.send(.scanQR(.delegate(.connectionSecretsFromScannedQR(secrets)))) {
			$0 = .connectUsingSecrets(.init(connectionSecrets: secrets))
		}
	}

	func test__GIVEN__connecting__WHEN__connected__THEN_we_delegate_to_parent_reducer() async throws {
		let secrets = ConnectionSecrets.placeholder
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: .placeholder)
			),
			reducer: NewConnection()
		)
		let connectedClient = P2P.ConnectionForClient(
			client: P2PClient(
				displayName: "test",
				connectionPassword: secrets.connectionPassword.data.data
			),
			connection: Connection.noop
		)
		await store.send(.connectUsingSecrets(.delegate(.connected(
			connectedClient
		))))
		await store.receive(.delegate(.newConnection(connectedClient)))
	}

	func test__GIVEN__new_connected_client__WHEN__user_dismisses_flow__THEN__connection_is_saved_but_without_name() async throws {
		let secrets = ConnectionSecrets.placeholder
		let connection = Connection.noop

		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: .placeholder, connectedConnection: connection)
			),
			reducer: NewConnection()
		)

		await store.send(.internal(.view(.dismissButtonTapped)))
		await store.receive(.delegate(.newConnection(.init(client: .init(displayName: "Unnamed", connectionPassword: secrets.connectionPassword.data.data), connection: connection))))
	}

	func test__GIVEN_new_connected_client__WHEN__user_confirms_name__THEN__connection_is_saved_with_that_name_trimmed() async throws {
		let secrets = ConnectionSecrets.placeholder
		let connection = Connection.noop
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: secrets, connectedConnection: connection)
			),
			reducer: NewConnection()
		)
		let connectionName = "Foobar"
		await store.send(.connectUsingSecrets(.view(.nameOfConnectionChanged(connectionName + " ")))) {
			$0 = .connectUsingSecrets(.init(connectionSecrets: secrets, connectedConnection: connection, nameOfConnection: connectionName + " "))
		}
		await store.send(.connectUsingSecrets(.view(.confirmNameButtonTapped)))
		let connectedClient = P2P.ConnectionForClient(
			client: .init(
				displayName: connectionName,
				connectionPassword: secrets.connectionPassword.data.data
			),
			connection: connection
		)
		await store.receive(.connectUsingSecrets(.delegate(.connected(connectedClient))))
		await store.receive(.delegate(.newConnection(
			connectedClient
		))
		)
	}
}
