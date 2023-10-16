import ComposableArchitecture
import SwiftUI
struct VisitHub: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		public init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case visitHubButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case displayHub
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .visitHubButtonTapped:
			.send(.delegate(.displayHub))
		}
	}
}
