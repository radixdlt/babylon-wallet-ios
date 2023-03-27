import CameraPermissionClient
import FeaturePrelude

// MARK: - DoScanQR
public struct DoScanQR: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scanMode: QRScanMode
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		public var manualQRContent: String

		public init(
			scanMode: QRScanMode = .default,
			manualQRContent: String = ""
		) {
			self.scanMode = scanMode
			self.manualQRContent = manualQRContent
		}
		#else
		public init(scanMode: QRScanMode = .default) {
			self.scanMode = scanMode
		}
		#endif // macOS
	}

	public enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case macInputQRContentChanged(String)
		case macConnectButtonTapped
		#endif // macOS
	}

	public enum DelegateAction: Sendable, Equatable {
		case scanned(String)
	}

	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case let .macInputQRContentChanged(manualQRContent):
			state.manualQRContent = manualQRContent
			return .none

		case .macConnectButtonTapped:
			return .send(.delegate(.scanned(qrString)))
		#endif // macOS

		case let .scanned(.success(qrString)):
			return .send(.delegate(.scanned(qrString)))

		case let .scanned(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}
