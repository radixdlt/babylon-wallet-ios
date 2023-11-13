import ComposableArchitecture
import SwiftUI
public struct AssetTransferMessage: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Kind: Sendable, Hashable {
			case `private`
			case `public`
		}

		public let kind: Kind = .public // only public is supported for now
		public var message: String
		public var focused: Bool = true

		@PresentationState
		public var destination: Destination.State?

		init(message: String) {
			self.message = message
		}

		static var empty: Self {
			.init(message: "")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case messageKindTapped
		case removeMessageTapped
		case focusChanged(Bool)
		case messageChanged(String)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removed
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case messageMode(MessageMode.State)
		}

		public enum Action: Sendable, Equatable {
			case messageMode(MessageMode.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.messageMode, action: /Action.messageMode) {
				MessageMode()
			}
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
