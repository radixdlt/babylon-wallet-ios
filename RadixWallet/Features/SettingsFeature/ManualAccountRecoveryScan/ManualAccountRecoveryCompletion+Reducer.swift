import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCompletetion
public struct ManualAccountRecoveryCompletion: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finish
	}

	// MARK: - Reducer

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			.send(.delegate(.finish))
		}
	}
}
