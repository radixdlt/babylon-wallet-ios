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
		) { _ in
		}
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
		) { _ in
		}
		let connectedClient = P2P.ConnectedClient(
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
}
