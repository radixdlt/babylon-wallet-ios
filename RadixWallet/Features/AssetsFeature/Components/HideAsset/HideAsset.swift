// MARK: - HideAsset
@Reducer
public struct HideAsset: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		let asset: AssetAddress
		var shouldShow = true

		@Presents
		var destination: Destination.State? = nil

		public init(asset: AssetAddress) {
			self.asset = asset
		}
	}

	public typealias Action = FeatureAction<Self>

	public enum InternalAction: Sendable, Equatable {
		case setShouldShow(Bool)
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case buttonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case didHideAsset
	}

	// MARK: - Destination
	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Hashable, Sendable {
			case confirmation
		}

		@CasePathable
		public enum Action: Equatable, Sendable {
			case confirmation(ConfirmationAction)
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return shouldShowEffect(state: state)

		case .buttonTapped:
			state.destination = .confirmation
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setShouldShow(value):
			state.shouldShow = value
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmation(.confirm):
			state.destination = nil
			return hideAssetEffect(state: state)
		case .confirmation(.cancel):
			state.destination = nil
			return .none
		}
	}
}

private extension HideAsset {
	func shouldShowEffect(state: State) -> Effect<Action> {
		.run { send in
			let isXrd: Bool
			switch state.asset {
			case let .fungible(resource):
				let networkId = await gatewaysClient.getCurrentNetworkID()
				isXrd = resource.isXRD(on: networkId)
			case .nonFungible, .poolUnit:
				isXrd = false
			}
			if isXrd {
				await send(.internal(.setShouldShow(false)))
			} else {
				let hiddenAssets = await appPreferencesClient.getPreferences().assets.hiddenAssets
				let isAlreadyHidden = hiddenAssets.contains(state.asset)
				await send(.internal(.setShouldShow(!isAlreadyHidden)))
			}
		}
	}

	func hideAssetEffect(state: State) -> Effect<Action> {
		.run { send in
			try await appPreferencesClient.updating { preferences in
				preferences.assets.hideAsset(asset: state.asset)
			}
			await send(.delegate(.didHideAsset))
		}
	}
}
