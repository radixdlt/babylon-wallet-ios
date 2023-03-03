import CameraPermissionClient
import FeaturePrelude

// MARK: - ScanQR
public struct ScanQR: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		public var connectionPassword: String

		public init(
			connectionPassword: String = ""
		) {
			self.connectionPassword = connectionPassword
		}
		#else
		public init() {}
		#endif // macOS
	}

	public enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case macInputConnectionPasswordChanged(String)
		case macConnectButtonTapped
		#endif // macOS
	}

	public enum InternalAction: Sendable, Equatable {
		case connectionSecretsFromScannedStringResult(TaskResult<ConnectionPassword>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case connectionSecretsFromScannedQR(ConnectionPassword)
	}

	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case let .macInputConnectionPasswordChanged(connectionPassword):
			state.connectionPassword = connectionPassword
			return .none

		case .macConnectButtonTapped:
			return parseConnectionPassword(hexString: state.connectionPassword)
		#endif // macOS

		case let .scanned(.success(qrString)):
			return parseConnectionPassword(hexString: qrString)

		case let .scanned(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .connectionSecretsFromScannedStringResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .connectionSecretsFromScannedStringResult(.success(connectionSecrets)):
			return .send(.delegate(.connectionSecretsFromScannedQR(connectionSecrets)))
		}
	}

	private func parseConnectionPassword(hexString: String) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.connectionSecretsFromScannedStringResult(
				TaskResult {
                                        try  ConnectionPassword.init(.init(hex: hexString))
				}
			)))
		}
	}
}
