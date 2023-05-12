import FeaturePrelude

public struct AssetTransferMessage: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Kind: Sendable, Hashable {
			case `private`
			case `public`
		}

		public var kind: Kind
		public var message: String

		public init(kind: Kind, message: String) {
			self.kind = kind
			self.message = message
		}

		static var empty: Self {
			.init(kind: .private, message: "")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case removeMessageTapped
		case messageChanged(String)
		case messageFocusChanged
		case focusChanged(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removed
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
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
