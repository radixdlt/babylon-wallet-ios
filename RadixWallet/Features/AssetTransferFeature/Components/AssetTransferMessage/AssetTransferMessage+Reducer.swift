import ComposableArchitecture
import SwiftUI

struct AssetTransferMessage: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Kind: Sendable, Hashable {
			case `private`
			case `public`
		}

		let kind: Kind = .public // only public is supported for now
		var message: String
		var focused: Bool = true

		@PresentationState
		var destination: Destination.State?

		init(message: String) {
			self.message = message
		}

		static var empty: Self {
			.init(message: "")
		}
	}

	enum ViewAction: Sendable, Equatable {
		case messageKindTapped
		case removeMessageTapped
		case focusChanged(Bool)
		case messageChanged(String)
	}

	enum DelegateAction: Sendable, Equatable {
		case removed
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case messageMode(MessageMode.State)
		}

		enum Action: Sendable, Equatable {
			case messageMode(MessageMode.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.messageMode, action: /Action.messageMode) {
				MessageMode()
			}
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .messageKindTapped:
			state.destination = .messageMode(.init())
			return .none

		case let .focusChanged(focused):
			state.focused = focused
			return .none

		case .removeMessageTapped:
			return .send(.delegate(.removed))

		case let .messageChanged(message):
			state.message = message
			return .none
		}
	}
}
