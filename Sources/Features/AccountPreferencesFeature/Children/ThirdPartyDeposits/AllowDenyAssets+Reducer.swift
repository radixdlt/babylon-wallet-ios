import EngineKit
import FeaturePrelude

// MARK: - AllowDenyAssets
public struct AllowDenyAssets: FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum List: CaseIterable, Hashable {
			case allow
			case deny
		}

		var allowList: Set<ThirdPartyDeposits.DepositAddress> = []
		var denyList: Set<ThirdPartyDeposits.DepositAddress> = []
		var list: List
		var addressesList: ResourcesList.State

		init() {
			self.allowList = []
			self.denyList = []
			self.list = .allow
			self.addressesList = .init(mode: .allowDenyAssets(.allow), thirdPartyDeposits: .default)
		}
	}

	public enum ViewAction: Equatable {
		case listChanged(State.List)
	}

	public enum ChildAction: Sendable, Equatable {
		case addressesList(ResourcesList.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.addressesList, action: /Action.child .. ChildAction.addressesList) {
			ResourcesList()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .listChanged(list):
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .addressesList:
			return .none
		}
	}
}
