import Cryptography
import FeaturePrelude

// MARK: - NameNewEntity
public struct NameNewEntity<Entity: EntityProtocol>: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.confirmNameButtonTapped)):
			guard let sanitizedName = state.sanitizedName else {
				return .none
			}
			state.focusedField = nil
			return .run { send in
				await send(.delegate(.named(sanitizedName)))
			}

		case let .internal(.view(.textFieldChanged(inputtedName))):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmed())
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(focus))))
			}

		case .internal(.view(.viewAppeared)):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.entityName))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .delegate: return .none
		}
	}
}
