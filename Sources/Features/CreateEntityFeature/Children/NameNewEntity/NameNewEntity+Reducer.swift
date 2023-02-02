import Cryptography
import FeaturePrelude

// MARK: - NameNewEntity
public struct NameNewEntity<Entity: EntityProtocol & Equatable & Sendable>: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.confirmNameButtonTapped)):
			state.focusedField = nil
			return .run { [name = state.sanitizedName] send in
				await send(.delegate(.named(name)))
			}

		case let .internal(.view(.textFieldChanged(accountName))):
			state.inputtedName = accountName
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(focus))))
			}

		case .internal(.view(.viewAppeared)):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.accountName))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .delegate: return .none
		}
	}
}
