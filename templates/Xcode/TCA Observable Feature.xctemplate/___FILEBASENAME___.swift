// MARK: - ___VARIABLE_featureName___
@Reducer
public struct ___VARIABLE_featureName___: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public typealias Action = FeatureAction<Self>

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}
}
