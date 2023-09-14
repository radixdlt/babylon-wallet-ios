import FeaturePrelude

// MARK: - ResourceAsset
// Higher order reducer composing all types of assets that can be transferred
public struct ResourceAsset: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID {
			switch self {
			case let .fungibleAsset(asset):
				return asset.id
			case let .nonFungibleAsset(asset):
				return asset.id
			}
		}

		case fungibleAsset(FungibleResourceAsset.State)
		case nonFungibleAsset(NonFungibleResourceAsset.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.Action)
		case nonFungibleAsset(NonFungibleResourceAsset.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.DelegateAction)
		case removed
	}

	public enum ViewAction: Equatable, Sendable {
		case removeTapped
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifCaseLet(/State.fungibleAsset, action: /Action.child .. ChildAction.fungibleAsset) {
				FungibleResourceAsset()
			}
			.ifCaseLet(/State.nonFungibleAsset, action: /Action.child .. ChildAction.nonFungibleAsset) {
				NonFungibleResourceAsset()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .fungibleAsset(.delegate(action)):
			return .send(.delegate(.fungibleAsset(action)))
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}

extension ResourceAsset.State {
	mutating func unsetFocus() {
		if case var .fungibleAsset(state) = self, state.focused {
			state.focused = false
			self = .fungibleAsset(state)
		}
	}
}
