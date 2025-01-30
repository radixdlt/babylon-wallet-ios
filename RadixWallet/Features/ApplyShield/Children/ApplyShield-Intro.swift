extension ApplyShield {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let shieldID: SecurityStructureId
			var shieldName: DisplayName?
			var hasEnoughXRD = true
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
			case startApplyingButtonTapped
			case skipButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case setShieldName(DisplayName)
		}

		enum DelegateAction: Sendable, Equatable {
			case skip
		}

		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				.run { [shieldID = state.shieldID] send in
					// TODO: expose `security_structure_of_factor_source_ids_by_security_structure_id` in Sargon
					guard let shield = try SargonOs.shared.securityStructuresOfFactorSourceIds()
						.first(where: { $0.metadata.id == shieldID }) else { return }
					await send(.internal(.setShieldName(shield.metadata.displayName)))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			case .startApplyingButtonTapped:
				.none
			case .skipButtonTapped:
				.send(.delegate(.skip))
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .setShieldName(name):
				state.shieldName = name
				return .none
			}
		}
	}
}
