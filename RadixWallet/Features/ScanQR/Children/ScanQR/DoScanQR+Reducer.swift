import ComposableArchitecture
import SwiftUI

// MARK: - ScanQR
public struct ScanQR: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scanInstructions: String
		public let scanMode: QRScanMode
		#if targetEnvironment(simulator)
		public var manualQRContent: String

		public init(
			scanInstructions: String,
			scanMode: QRScanMode = .default,
			manualQRContent: String = ""
		) {
			self.scanInstructions = scanInstructions
			self.scanMode = scanMode
			self.manualQRContent = manualQRContent
		}
		#else
		public init(
			scanInstructions: String,
			scanMode: QRScanMode = .default
		) {
			self.scanInstructions = scanInstructions
			self.scanMode = scanMode
		}
		#endif // sim
	}

	public enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if targetEnvironment(simulator)
		case macInputQRContentChanged(String)
		case macConnectButtonTapped
		#endif // sim
	}

	public enum DelegateAction: Sendable, Equatable {
		case scanned(String)
	}

	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		#if targetEnvironment(simulator)
		case let .macInputQRContentChanged(manualQRContent):
			state.manualQRContent = manualQRContent
			return .none

		case .macConnectButtonTapped:
			return .send(.delegate(.scanned(state.manualQRContent)))
		#endif // sim

		case let .scanned(.success(qrString)):
			return .send(.delegate(.scanned(qrString)))

		case let .scanned(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}
