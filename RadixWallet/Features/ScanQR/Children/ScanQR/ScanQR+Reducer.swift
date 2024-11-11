import ComposableArchitecture
import SwiftUI

// MARK: - ScanQR
@Reducer
struct ScanQR: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: Kind
		#if targetEnvironment(simulator)
		var manualQRContent: String

		init(
			kind: Kind,
			manualQRContent: String = ""
		) {
			self.kind = kind
			self.manualQRContent = manualQRContent
		}
		#else
		init(
			kind: Kind
		) {
			self.kind = kind
		}
		#endif // sim
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if targetEnvironment(simulator)
		case manualQRContentChanged(String)
		case macConnectButtonTapped
		#endif // sim
	}

	enum DelegateAction: Sendable, Equatable {
		case scanned(String)
	}

	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
	enum Kind: Sendable, Hashable {
		case connectorExtension
		case account
		case importOlympia
	}
}
