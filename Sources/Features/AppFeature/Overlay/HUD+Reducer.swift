import FeaturePrelude
import OverlayWindowClient

// MARK: - HUD
struct HUD: FeatureReducer {
	struct State: Sendable, Hashable {
		static let hiddenOffset: CGFloat = -128.0
		static let autoDismissDelay: Double = 1.0

		let content: OverlayWindowClient.Item.HUD
		var offset = Self.hiddenOffset
	}

	enum ViewAction: Equatable {
		case onAppear
		case dismissCompleted
	}

	enum DelegateAction: Equatable {
		case dismiss
	}

	enum InternalAction: Equatable {
		case autoDimiss
	}

	@Dependency(\.continuousClock) var clock

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .dismissCompleted:
			if state.offset == State.hiddenOffset {
				/// Notify the delegate only after the animation did complete.
				return .send(.delegate(.dismiss))
			} else {
				return .run { send in
					try await clock.sleep(for: .seconds(State.autoDismissDelay))
					await send(.internal(.autoDimiss), animation: .hudAnimation)
				}
			}
		case .onAppear:
			state.offset = 0
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .autoDimiss:
			state.offset = State.hiddenOffset
			return .none
		}
	}
}
