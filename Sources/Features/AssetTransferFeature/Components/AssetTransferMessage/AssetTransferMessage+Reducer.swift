import FeaturePrelude

public struct AssetTransferMessage: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Kind: Sendable, Hashable {
			case `private`
			case `public`
		}

		public var kind: Kind
		public var message: String

		@PresentationState
		public var destination: Destinations.State?

		public init(kind: Kind, message: String) {
			self.kind = kind
			self.message = message
		}

		static var empty: Self {
			.init(kind: .private, message: "")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case messageKindTapped
		case removeMessageTapped
		case messageChanged(String)
		case messageFocusChanged
		case focusChanged(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removed
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case messageMode(MessageMode.State)
		}

		public enum Action: Sendable, Equatable {
			case messageMode(MessageMode.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.messageMode, action: /Action.messageMode) {
				MessageMode()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .messageKindTapped:
			state.destination = .messageMode(.init())
			return .none
		case .removeMessageTapped:
			return .send(.delegate(.removed))
		case let .messageChanged(message):
			state.message = message
			return .none
		case .messageFocusChanged:
			return .none
		case let .focusChanged(focused):
			// state.isFocused = focused
			return .none
		}
	}
}
