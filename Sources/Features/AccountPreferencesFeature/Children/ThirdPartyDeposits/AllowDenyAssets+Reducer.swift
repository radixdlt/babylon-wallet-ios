import EngineKit
import FeaturePrelude

// MARK: - AllowDenyAssets
public struct AllowDenyAssets: FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum List: CaseIterable, Hashable {
			case allow
			case deny
		}

		var allowList: Set<DepositAddress> = []
		var denyList: Set<DepositAddress> = []
		var list: List
		var addressesList: ResourcesList.State

		@PresentationState
		var destinations: Destinations.State? = nil

		init() {
			self.allowList = []
			self.denyList = []
			self.list = .allow
			self.addressesList = .init()
			self.destinations = nil
		}
	}

	public enum ViewAction: Equatable {
		case listChanged(State.List)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
		case addressesList(ResourcesList.Action)
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case addAsset(AddAsset.State)
			case confirmAssetDeletion(AlertState<Action.ConfirmDeletionAlert>)
		}

		public enum Action: Hashable {
			case addAsset(AddAsset.Action)
			case confirmAssetDeletion(ConfirmDeletionAlert)

			public enum ConfirmDeletionAlert: Sendable, Hashable {
				case confirmTapped(DepositAddress)
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addAsset, action: /Action.addAsset) {
				AddAsset()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.addressesList, action: /Action.child .. ChildAction.addressesList) {
			ResourcesList()
		}

		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .listChanged(list):
			state.list = list
			switch list {
			case .allow:
				state.addressesList = .init(addresses: state.allowList)
			case .deny:
				state.addressesList = .init(addresses: state.denyList)
			}

			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destinations:
			return .none
		case let .addressesList(.delegate(.addressAdded(address))):
			switch state.list {
			case .allow:
				state.allowList.insert(address)
			case .deny:
				state.denyList.insert(address)
			}
			return .none
		case let .addressesList(.delegate(.addressRemoved(address))):
			switch state.list {
			case .allow:
				state.allowList.remove(address)
			case .deny:
				state.denyList.remove(address)
			}
			return .none
		case .addressesList:
			return .none
		}
	}
}

extension AllowDenyAssets.State.List {
	var removeConfirmationMessage: String {
		switch self {
		case .allow:
			return "The asset will be removed from the allow list"
		case .deny:
			return "The asset will be removed from the deny list"
		}
	}
}

// MARK: - FeatureAction + Hashable
extension FeatureAction: Hashable where Feature.ViewAction: Hashable, Feature.ChildAction: Hashable, Feature.InternalAction: Hashable, Feature.DelegateAction: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .view(action):
			hasher.combine(action)
		case let .internal(action):
			hasher.combine(action)
		case let .child(action):
			hasher.combine(action)
		case let .delegate(action):
			hasher.combine(action)
		}
	}
}
