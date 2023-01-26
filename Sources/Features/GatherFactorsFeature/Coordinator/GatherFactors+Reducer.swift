import FeaturePrelude
import ProfileClient

// MARK: - GatherFactors
public struct GatherFactors<Purpose: GatherFactorPurposeProtocol>: Sendable, ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.keychainClient) var keychainClient
	public init() {}
}

extension GatherFactors {
	public var body: some ReducerProtocol<State, Action> {
		CombineReducers {
			Scope(state: \.currentFactor, action: /Action.child .. Action.ChildAction.gatherFactor) {
				GatherFactor()
			}

			Reduce(self.core)
		}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.proceed)):
			precondition(state.canProceed)
			if state.isLast {
//				let result = try! GatherFactorsResult(
//					purpose: state.purpose,
//					results: .init(state.results.values)
//				)
//				return .run { send in
//					await send(.delegate(.finishedWithResult(result)))
//				}
				return .none
			} else {
				state.index += 1
				return .none
			}

		case let .child(.gatherFactor(.delegate(.finishedWithResult(id, result)))):
			state.results[id] = result
			return .none

		case .child, .delegate: return .none
		}
	}
}

public extension GatherFactors.State {
	var isLast: Bool {
		index == gatherFactors.count - 1
	}

	var canProceed: Bool {
		if isLast {
			return results.count == gatherFactors.count
		} else {
			return results[gatherFactors[index].id] != nil
		}
	}
}
