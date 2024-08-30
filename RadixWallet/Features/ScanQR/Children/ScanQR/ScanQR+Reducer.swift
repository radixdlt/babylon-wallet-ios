import ComposableArchitecture
import SwiftUI

// MARK: - ScanQR
public struct ScanQR: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		public let kind: Kind
		#if targetEnvironment(simulator)
		public var manualQRContent: String

		public init(
			kind: Kind,
			manualQRContent: String = ""
		) {
			self.kind = kind
			self.manualQRContent = manualQRContent
		}
		#else
		public init(
			kind: Kind
		) {
			self.kind = kind
		}
		#endif // sim
	}

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if targetEnvironment(simulator)
		case manualQRContentChanged(String)
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
		case let .manualQRContentChanged(manualQRContent):
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

// MARK: ScanQR.Kind
extension ScanQR {
	public enum Kind: Sendable, Hashable {
		case connectorExtension
		case account
		case importOlympia
	}
}
