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

		@PresentationState
		var destinations: Destinations.State? = nil
	}

	public enum ViewAction: Equatable {
		case listChanged(State.List)
		case addAssetTapped
		case assetRemove(DepositAddress)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
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
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .listChanged(list):
			state.list = list
			return .none
		case .addAssetTapped:
			state.destinations = .addAsset(.init(
				type: state.list,
				resourceAddress: "",
				alreadyAddedResources: state.allowList.union(state.denyList)
			))
			return .none
		case let .assetRemove(resource):
			state.destinations = .confirmAssetDeletion(.confirmAssetDeletion(state.list.removeConfirmationMessage, resourceAddress: resource))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.addAsset(.delegate(.addAddress(list, newAsset))))):
			switch list {
			case .allow:
				state.allowList.insert(newAsset)
			case .deny:
				state.denyList.insert(newAsset)
			}
			state.list = list
			state.destinations = nil
			return .none
		case let .destinations(.presented(.confirmAssetDeletion(.confirmTapped(resource)))):
			switch state.list {
			case .allow:
				state.allowList.remove(resource)
			case .deny:
				state.denyList.remove(resource)
			}
			return .none
		case .destinations:
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

extension AlertState<AllowDenyAssets.Destinations.Action.ConfirmDeletionAlert> {
	static func confirmAssetDeletion(
		_ message: String,
		resourceAddress: DepositAddress
	) -> AlertState {
		AlertState {
			TextState("Remove Asset")
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped(resourceAddress)) {
				TextState(L10n.Common.remove)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(message)
		}
	}
}
