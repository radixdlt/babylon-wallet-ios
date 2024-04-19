@testable import Radix_Wallet_Dev
import XCTest

// MARK: - NewConnectionTests
@MainActor
final class NewConnectionTests: TestCase {
	let scanInstruction = "instruction"
	func test__GIVEN__scanQR_screen__WHEN__secrets_with_invalid_signature_are_scanned__THEN__we_show_invalid_QR_error() async throws {
		let store = TestStore(
			// GIVEN
			// initial state
			initialState: NewConnection.State(
				root: .scanQR(.init(scanInstructions: scanInstruction, step: .scanQR(.init(scanInstructions: scanInstruction))))
			),
			reducer: NewConnection.init
		)
		let qrData = LinkConnectionQRData.placeholder
		let qrString = """
		{
		"purpose": "\(qrData.purpose.rawValue)",
		"password": "\(qrData.password.rawValue.data.hex())",
		"publicKey": "\(qrData.publicKey.rawValue.data.hex())",
		"signature": "\(qrData.signature.rawValue.data.hex())"
		}
		"""

		await store.send(.child(.scanQR(.child(.scanQR(.view(.scanned(.success(qrString))))))))

		await store.receive(.child(.scanQR(.child(.scanQR(.delegate(.scanned(qrString)))))))
		await store.receive(.child(.scanQR(.delegate(.scanned(qrString)))))

		await store.receive(.internal(.linkConnectionDataFromStringResult(.success(qrData)))) {
			$0.linkConnectionQRData = qrData
		}
		await store.receive(.internal(.showErrorAlert(.invalidQRCode))) {
			$0.destination = .errorAlert(.invalidQRCode)
		}
	}

	func test__GIVEN_new_connection_approval_screen__WHEN__user_finishes_flow__THEN__connection_we_start_connect_using_secrets() async throws {
		let connectionName = "Foobar"
		let purpose = NewConnectionApproval.State.Purpose.approveNewConnection
		let p2pLink = P2PLink(
			connectionPassword: .placeholder,
			publicKey: .placeholder,
			purpose: .general,
			displayName: connectionName
		)
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State(
				root: .connectionApproval(.init(purpose: purpose)),
				linkConnectionQRData: .placeholder
			),
			reducer: NewConnection.init
		) {
			$0.radixConnectClient.connectP2PLink = { _ in }
		}

		await store.send(.child(.connectionApproval(.view(.continueButtonTapped))))

		await store.receive(.child(.connectionApproval(.delegate(.approved(purpose))))) {
			$0.root = .nameConnection(.init())
		}

		await store.send(.child(.nameConnection(.view(.nameOfConnectionChanged(connectionName + "\n"))))) {
			$0.root = .nameConnection(.init(
				nameOfConnection: connectionName
			))
		}
		await store.send(.child(.nameConnection(.view(.confirmNameButtonTapped))))

		await store.receive(.child(.nameConnection(.delegate(.nameSet(connectionName)))))
		await store.receive(.internal(.establishConnection(connectionName))) {
			$0.root = .nameConnection(.init(
				isConnecting: true,
				nameOfConnection: connectionName
			))
			$0.connectionName = connectionName
		}
		await store.receive(.internal(.establishConnectionResult(.success(p2pLink)))) {
			$0.root = .nameConnection(.init(
				isConnecting: false,
				nameOfConnection: connectionName
			))
		}
		await store.receive(.delegate(.newConnection(p2pLink)))
	}

	func test__GIVEN_existing_connection_approval_screen__WHEN__user_taps_continue__THEN__we_start_connect_using_secrets() async throws {
		let connectionName = "Foobar"
		let purpose = NewConnectionApproval.State.Purpose.approveExisitingConnection(connectionName)
		let p2pLink = P2PLink(
			connectionPassword: .placeholder,
			publicKey: .placeholder,
			purpose: .general,
			displayName: connectionName
		)
		let store = TestStore(
			// GIVEN initial state
			initialState: NewConnection.State(
				root: .connectionApproval(.init(purpose: purpose)),
				linkConnectionQRData: .placeholder
			),
			reducer: NewConnection.init
		) {
			$0.radixConnectClient.connectP2PLink = { _ in }
		}

		await store.send(.child(.connectionApproval(.view(.continueButtonTapped))))

		await store.receive(.child(.connectionApproval(.delegate(.approved(purpose)))))
		await store.receive(.internal(.establishConnection(connectionName))) {
			$0.root = .connectionApproval(.init(
				purpose: purpose,
				isConnecting: true
			))
			$0.connectionName = connectionName
		}
		await store.receive(.internal(.establishConnectionResult(.success(p2pLink)))) {
			$0.root = .connectionApproval(.init(
				purpose: purpose,
				isConnecting: false
			))
		}
		await store.receive(.delegate(.newConnection(p2pLink)))
	}
}
