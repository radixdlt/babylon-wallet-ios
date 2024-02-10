import ComposableArchitecture

////@Reducer
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account
	}

	public struct ViewAction: Sendable, Hashable {}

	public var body: some ReducerOf<Self> {
		EmptyReducer()
	}
}
