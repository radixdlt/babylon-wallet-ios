import ComposableArchitecture
import SwiftUI

// MARK: - ManageSecurityStructureStart
public struct ManageSecurityStructureStart: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case simpleFlow
		case advancedFlow
	}

	public enum DelegateAction: Sendable, Equatable {
		case simpleFlow
		case advancedFlow
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .simpleFlow:
			.send(.delegate(.simpleFlow))
		case .advancedFlow:
			.send(.delegate(.advancedFlow))
		}
	}
}
