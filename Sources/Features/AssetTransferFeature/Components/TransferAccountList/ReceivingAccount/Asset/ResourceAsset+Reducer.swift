import FeaturePrelude

public struct ResourceAsset: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(/State.fungibleAsset, action: /Action.child .. ChildAction.fungibleAsset) {
				FungibleResourceAsset()
			}
			.ifCaseLet(/State.nonFungibleAsset, action: /Action.child .. ChildAction.nonFungibleAsset) {
				NonFungibleResourceAsset()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .fungibleAsset(.delegate(action)):
			return .send(.delegate(.fungibleAsset(action)))
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
