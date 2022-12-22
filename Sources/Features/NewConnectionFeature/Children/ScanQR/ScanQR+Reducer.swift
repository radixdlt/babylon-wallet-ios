import CameraPermissionClient
import Common
import ComposableArchitecture
import ErrorQueue
import P2PModels

// MARK: - ScanQR
public struct ScanQR: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue

	public init() {}
}

public extension ScanQR {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case let .internal(.view(.macInputConnectionPasswordChanged(connectionPassword))):
			state.connectionPassword = connectionPassword
			return .none
		case .internal(.view(.macConnectButtonTapped)):
			return parseConnectionPassword(hexString: state.connectionPassword)
		#endif // macOS

		case let .internal(.view(.scanResult(.success(qrString)))):
			return parseConnectionPassword(hexString: qrString)

		case let .internal(.view(.scanResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none
		case let .internal(.system(.connectionSecretsFromScannedStringResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none
		case let .internal(.system(.connectionSecretsFromScannedStringResult(.success(connectionSecrets)))):
			return .run { send in
				await send(.delegate(.connectionSecretsFromScannedQR(connectionSecrets)))
			}
		case .delegate:
			return .none
		}
	}
}

private extension ScanQR {
	func parseConnectionPassword(hexString: String) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.connectionSecretsFromScannedStringResult(
				TaskResult {
					let password = try ConnectionPassword(hexString: hexString)
					return try ConnectionSecrets.from(connectionPassword: password)
				}
			))))
		}
	}
}
