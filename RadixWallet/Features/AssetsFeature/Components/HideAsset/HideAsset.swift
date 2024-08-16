// MARK: - HideAsset
@Reducer
public struct HideAsset: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		let asset: AssetAddress
		var isAlreadyHidden = false
		var isXrd = false

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

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			isXrdEffect(state: state)
				.merge(with: isAlreadyHiddenEffect(state: state))

		case .buttonTapped:
			.none
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

	private func isXrdEffect(state: State) -> Effect<Action> {
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

	private func isAlreadyHiddenEffect(state: State) -> Effect<Action> {
		.run { send in
			let hiddenAssets = await appPreferencesClient.getPreferences().assets
			let isAlreadyHidden = hiddenAssets.contains(where: { $0.assetAddress == state.asset })
			await send(.internal(.setIsAlreadyHidden(isAlreadyHidden)))
		}
	}
}

extension AppPreferencesClient {
	func shouldAllowHiding(asset: AssetAddress) async -> Bool {
		switch asset {
		case let .fungible(resourceAddress):
			break
		case .nonFungible, .poolUnit:
			break
		}
		return false
	}
}
