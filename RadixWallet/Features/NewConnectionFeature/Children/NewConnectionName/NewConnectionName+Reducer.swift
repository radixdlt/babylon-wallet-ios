import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionName
public struct NewConnectionName: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isConnecting: Bool
		public var nameOfConnection: String
		public var focusedField: Field?

		public var isNameValid: Bool { !nameOfConnection.isEmpty }

		public init(
			isConnecting: Bool = false,
			focusedField: Field? = nil,
			nameOfConnection: String = ""
		) {
			self.focusedField = focusedField
			self.isConnecting = isConnecting
			self.nameOfConnection = nameOfConnection
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case textFieldFocused(NewConnectionName.State.Field?)
		case nameOfConnectionChanged(String)
		case confirmNameButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(NewConnectionName.State.Field?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case nameSet(String)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .send(.view(.textFieldFocused(.connectionName)))

		case let .textFieldFocused(focus):
			return .send(.internal(.focusTextField(focus)))

		case let .nameOfConnectionChanged(connectionName):
			state.nameOfConnection = connectionName.trimmingNewlines()
			return .none

		case .confirmNameButtonTapped:
			return .send(.delegate(.nameSet(state.nameOfConnection)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none
		}
	}
}
