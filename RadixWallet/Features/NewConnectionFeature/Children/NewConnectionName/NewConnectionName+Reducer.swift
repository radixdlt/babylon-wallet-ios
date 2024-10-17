import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionName
struct NewConnectionName: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isConnecting: Bool
		var nameOfConnection: String
		var focusedField: Field?

		var isNameValid: Bool { !nameOfConnection.isEmpty }

		init(
			isConnecting: Bool = false,
			focusedField: Field? = nil,
			nameOfConnection: String = ""
		) {
			self.focusedField = focusedField
			self.isConnecting = isConnecting
			self.nameOfConnection = nameOfConnection
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case textFieldFocused(NewConnectionName.State.Field?)
		case nameOfConnectionChanged(String)
		case confirmNameButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case nameSet(String)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return focusTextField(.connectionName, state: &state)

		case let .textFieldFocused(focus):
			return focusTextField(focus, state: &state)

		case let .nameOfConnectionChanged(connectionName):
			state.nameOfConnection = connectionName.trimmingNewlines()
			return .none

		case .confirmNameButtonTapped:
			return .send(.delegate(.nameSet(state.nameOfConnection)))
		}
	}

	private func focusTextField(_ focus: NewConnectionName.State.Field?, state: inout State) -> Effect<Action> {
		state.focusedField = focus
		return .none
	}
}
