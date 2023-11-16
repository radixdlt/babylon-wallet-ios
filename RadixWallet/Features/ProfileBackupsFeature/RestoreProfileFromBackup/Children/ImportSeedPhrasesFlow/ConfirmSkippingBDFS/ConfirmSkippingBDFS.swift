// MARK: - ConfirmSkippingBDFS
public struct ConfirmSkippingBDFS: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var flashScrollIndicators = false
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case confirmTapped
		case backButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case flashScrollIndicator
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmed
		case cancel
	}

	@Dependency(\.continuousClock) var clock

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				try? await clock.sleep(for: .milliseconds(700))
				await send(.internal(.flashScrollIndicator))
			}
		case .confirmTapped:
			.send(.delegate(.confirmed))
		case .backButtonTapped:
			.send(.delegate(.cancel))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .flashScrollIndicator:
			state.flashScrollIndicators = true
			return .none
		}
	}
}
