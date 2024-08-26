import ComposableArchitecture
import SwiftUI

@Reducer
public struct IntroductionToPersonas: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {}

	public typealias Action = FeatureAction<Self>

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case done
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case .continueButtonTapped:
			.send(.delegate(.done))
		}
	}
}
