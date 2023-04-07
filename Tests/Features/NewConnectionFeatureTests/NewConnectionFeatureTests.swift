import FeatureTestingPrelude
@testable import NewConnectionFeature
import RadixConnectModels

// MARK: - NewConnectionTests
@MainActor
final class NewConnectionTests: TestCase {
	let scanInstruction = "instruction"
	func test__GIVEN__scanQR_screen__WHEN__secrets_are_scanned__THEN__we_start_connect_using_secrets() async throws {
		let store = TestStore(
			// GIVEN
			// initial state
			initialState: NewConnection.State.scanQR(.init(scanInstructions: scanInstruction, step: .scanQR(.init(scanInstructions: scanInstruction)))),
			reducer: NewConnection()
		)
		let password = ConnectionPassword.placeholder

		let qrString = password.rawValue.data.hex()

		// WHEN
		// secrets are scanned
		await store.send(.child(.scanQR(.child(.scanQR(.view(.scanned(.success(
			qrString
		))))))))

		await store.receive(.child(.scanQR(.child(.scanQR(.delegate(.scanned(qrString)))))))
		await store.receive(.child(.scanQR(.delegate(.scanned(qrString)))))

		// THEN
		// we start connect
		await store.receive(.internal(.connectionPasswordFromStringResult(.success(password)))) {
			$0 = .connectUsingSecrets(.init(connectionPassword: password))
		}
	}

	func test__GIVEN__connecting__WHEN__connected__THEN_we_delegate_to_parent_reducer() async throws {
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionPassword: .placeholder)
			),
			reducer: NewConnection()
		)
		let connectedClient = P2PLink(connectionPassword: .placeholder, displayName: "name")

		await store.send(.child(.connectUsingSecrets(.delegate(.connected(connectedClient)))))
		await store.receive(.delegate(.newConnection(connectedClient)))
	}

	func test__GIVEN__new_connected_client__WHEN__user_dismisses_flow__THEN__connection_is_saved_but_without_name() async throws {
		let connection = P2PLink(connectionPassword: .placeholder, displayName: "Unnamed")

		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionPassword: connection.connectionPassword)
			),
			reducer: NewConnection()
		)

		await store.send(.view(.closeButtonTapped))
		await store.receive(.child(.connectUsingSecrets(.delegate(.connected(connection)))))
		await store.receive(.delegate(.newConnection(connection)))
	}

	func test__GIVEN_new_connected_client__WHEN__user_confirms_name__THEN__connection_is_saved_with_that_name_trimmed() async throws {
		let password = ConnectionPassword.placeholder

		let clock = TestClock()
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State.connectUsingSecrets(
				ConnectUsingSecrets.State(connectionPassword: password)
			),
			reducer: NewConnection()
		) {
			$0.continuousClock = clock
		}
		let addP2PWithPassword = ActorIsolated<ConnectionPassword?>(nil)
		store.dependencies.radixConnectClient.addP2PWithPassword = { password in
			await addP2PWithPassword.setValue(password)
		}
		let connectionName = "Foobar"
		await store.send(.child(.connectUsingSecrets(.view(.nameOfConnectionChanged(connectionName + " "))))) {
			$0 = .connectUsingSecrets(.init(
				connectionPassword: password,
				nameOfConnection: connectionName,
				isNameValid: true
			))
		}

		await store.send(.child(.connectUsingSecrets(.view(.confirmNameButtonTapped)))) {
			$0 = .connectUsingSecrets(.init(
				connectionPassword: password,
				isConnecting: true,
				nameOfConnection: connectionName,
				isNameValid: true
			))
		}

		await clock.advance(by: .seconds(1))

		let link = P2PLink(connectionPassword: password, displayName: connectionName)

		await store.receive(.child(.connectUsingSecrets(.internal(.establishConnectionResult(.success(password)))))) {
			$0 = .connectUsingSecrets(.init(
				connectionPassword: password,
				isConnecting: false,
				nameOfConnection: connectionName,
				isNameValid: true
			))
		}
		await store.receive(.child(.connectUsingSecrets(.internal(.cancelOngoingEffects))))
		await store.receive(.child(.connectUsingSecrets(.delegate(.connected(link)))))
		await store.receive(.delegate(.newConnection(link)))

		let addedP2PWithPassword = await addP2PWithPassword.value
		XCTAssertEqual(addedP2PWithPassword, password)
	}
}
