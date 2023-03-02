import CameraPermissionClient
import FeaturePrelude

// MARK: - ScanQR
public struct ScanQR: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue

	public init() {}
}

extension ScanQR {
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
		case let .internal(.system(.connectionPasswordFromScannedStringResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none
		case let .internal(.system(.connectionPasswordFromScannedStringResult(.success(connectionSecrets)))):
			return .run { send in
				await send(.delegate(.connectionSecretsFromScannedQR(connectionSecrets)))
			}
		case .delegate:
			return .none
		}
	}
}

extension ScanQR {
	fileprivate func parseConnectionPassword(hexString: String) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.connectionPasswordFromScannedStringResult(
				TaskResult {
					try ConnectionPassword(hex: hexString)
				}
			))))
		}
	}
}
