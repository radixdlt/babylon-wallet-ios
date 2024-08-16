// MARK: - HideAsset
@Reducer
public struct HideAsset: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public typealias Action = FeatureAction<Self>

	public enum ViewAction: Sendable, Equatable {
		case buttonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case didHideAsset
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .buttonTapped:
			.none
		}
	}
}
