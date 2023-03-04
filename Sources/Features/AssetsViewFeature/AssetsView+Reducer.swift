import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
			case tokens
			case nfts

			// TODO: uncomment when ready for implementation
			/*
			 case poolUnits
			 case badges
			 */

			var displayText: String {
				switch self {
				case .tokens:
					return L10n.AssetsView.tokens
				case .nfts:
					return L10n.AssetsView.nfts

					// TODO: uncomment when ready for implementation
					/*
					 case .poolUnits:
					 return L10n.AssetsView.poolUnits
					 case .badges:
					 return L10n.AssetsView.badges
					 */
				}
			}
		}

		public var kind: AssetKind
		public var fungibleTokenList: FungibleTokenList.State
		public var nonFungibleTokenList: NonFungibleTokenList.State

		public init(
			kind: AssetKind = .tokens,
			fungibleTokenList: FungibleTokenList.State,
			nonFungibleTokenList: NonFungibleTokenList.State
		) {
			self.kind = kind
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case listSelectorTapped(AssetsView.State.AssetKind)
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
			NonFungibleTokenList()
		}

		Scope(state: \.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
			FungibleTokenList()
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .listSelectorTapped(kind):
			state.kind = kind
			return .none
		}
	}
}
