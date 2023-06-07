import AddTrustedContactFactorSourceFeature
import FeaturePrelude

// MARK: - SimpleLostPhoneHelper
public struct SimpleLostPhoneHelper: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var addTrustedContactFactorSource: AddTrustedContactFactorSource.State?

		public init() {
			self.addTrustedContactFactorSource = .init()
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case addTrustedContactFactorSource(PresentationAction<AddTrustedContactFactorSource.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdFactorSource(TrustedContactFactorSource)
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$addTrustedContactFactorSource, action: /Action.child .. ChildAction.addTrustedContactFactorSource) {
				AddTrustedContactFactorSource()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addTrustedContactFactorSource(.presented(.delegate(.done(.success(trustedContactFS))))):
			state.addTrustedContactFactorSource = nil
			return .run { send in
				await send(.delegate(.createdFactorSource(trustedContactFS)))
				await dismiss()
			}

		case let .addTrustedContactFactorSource(.presented(.delegate(.done(.failure(error))))):
			let errorMessage = "Failed to create factor source, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			errorQueue.schedule(error)
			return .none

		default:
			return .none
		}
	}
}
