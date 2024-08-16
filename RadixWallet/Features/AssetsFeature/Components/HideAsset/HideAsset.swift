// MARK: - HideAsset
@Reducer
public struct HideAsset: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		let asset: AssetAddress
		fileprivate var isAlreadyHidden = false
		fileprivate var isXrd = false

		@Presents
		var destination: Destination.State? = nil

		public init(asset: AssetAddress) {
			self.asset = asset
		}

		var shouldShow: Bool {
			!(isAlreadyHidden || isXrd)
		}
	}

	public typealias Action = FeatureAction<Self>

	public enum InternalAction: Sendable, Equatable {
		case setIsXrd(Bool)
		case setIsAlreadyHidden(Bool)
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
			return isXrdEffect(state: state)
				.merge(with: isAlreadyHiddenEffect(state: state))

		case .buttonTapped:
			state.destination = .confirmation
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setIsXrd(value):
			state.isXrd = value
			return .none
		case let .setIsAlreadyHidden(value):
			state.isAlreadyHidden = value
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
	func isXrdEffect(state: State) -> Effect<Action> {
		.run { send in
			switch state.asset {
			case let .fungible(resource):
				let networkId = await gatewaysClient.getCurrentNetworkID()
				await send(.internal(.setIsXrd(resource.isXRD(on: networkId))))
			case .nonFungible, .poolUnit:
				await send(.internal(.setIsXrd(false)))
			}
		}
	}

	func isAlreadyHiddenEffect(state: State) -> Effect<Action> {
		.run { send in
			let hiddenAssets = await appPreferencesClient.getPreferences().assets
			let isAlreadyHidden = hiddenAssets.contains(where: { $0.assetAddress == state.asset })
			await send(.internal(.setIsAlreadyHidden(isAlreadyHidden)))
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
