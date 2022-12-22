import ComposableArchitecture
import Foundation
@testable import NewConnectionFeature
import Peer
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
		let secrets = ConnectionSecrets.placeholder
		let peer = Peer(connectionSecrets: secrets)
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
			peer: peer
		)
		await store.send(.child(.connectUsingSecrets(.delegate(.connected(
			connectedClient
		)))))
		await store.receive(.delegate(.newConnection(connectedClient)))
	}

	func test__GIVEN__new_connected_client__WHEN__user_dismisses_flow__THEN__connection_is_saved_but_without_name() async throws {
		let secrets = ConnectionSecrets.placeholder
		let peer = Peer(connectionSecrets: secrets)

		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: .placeholder, connectedPeer: peer)
			),
			reducer: NewConnection()
		)

		await store.send(.internal(.view(.dismissButtonTapped)))
		await store.receive(.delegate(.newConnection(.init(client: .init(displayName: "Unnamed", connectionPassword: secrets.connectionPassword.data.data), peer: peer))))
	}

	func test__GIVEN_new_connected_client__WHEN__user_confirms_name__THEN__connection_is_saved_with_that_name_trimmed() async throws {
		let secrets = ConnectionSecrets.placeholder
		let peer = Peer(connectionSecrets: secrets)
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionSecrets: secrets, connectedPeer: peer)
			),
			reducer: NewConnection()
		)
		let connectionName = "Foobar"
		await store.send(.child(.connectUsingSecrets(.view(.nameOfConnectionChanged(connectionName + " "))))) {
			$0 = .connectUsingSecrets(.init(
				connectionSecrets: secrets,
				connectedPeer: peer,
				nameOfConnection: connectionName + " ",
				isNameValid: true
			)
			)
		}
		let testScheduler = DispatchQueue.test
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		await store.send(.child(.connectUsingSecrets(.view(.confirmNameButtonTapped))))
		await testScheduler.advance(by: .seconds(1))
		let connectedClient = P2P.ConnectionForClient(
			client: .init(
				displayName: connectionName,
				connectionPassword: secrets.connectionPassword.data.data
			),
			peer: peer
		)

		await store.receive(.child(.connectUsingSecrets(.internal(.view(.textFieldFocused(nil))))))
		await store.receive(.child(.connectUsingSecrets(.delegate(.connected(connectedClient)))))
		await store.receive(.delegate(.newConnection(
			connectedClient
		))
		)

		await store.receive(.child(.connectUsingSecrets(.internal(.system(.focusTextField(.none))))))
	}
}
