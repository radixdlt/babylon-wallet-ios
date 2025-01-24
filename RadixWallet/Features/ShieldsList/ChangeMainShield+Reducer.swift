// MARK: - ChangeMainShield
@Reducer
struct ChangeMainShield: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let currentMain: ShieldForDisplay?
		var shields: [ShieldForDisplay] = []
		var selected: ShieldForDisplay?
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case selected(ShieldForDisplay)
		case confirmButtonTapped(ShieldForDisplay)
	}

	enum InternalAction: Sendable, Equatable {
		case setShields([ShieldForDisplay])
	}

	enum DelegateAction: Sendable, Equatable {
		case updated
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [current = state.currentMain] send in
				let shields = try SargonOS.shared.securityStructuresOfFactorSources()
					.map { ShieldForDisplay(shield: $0) }
					.filter { $0.id != current?.id }
				await send(.internal(.setShields(shields)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .selected(shield):
			state.selected = shield
			return .none

		case let .confirmButtonTapped(shield):
			return .run { send in
				//                try await SargonOS.shared.setMainShield(shieldId: shield.id)
				await send(.delegate(.updated))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setShields(shields):
			state.shields = shields
			return .none
		}
	}
}
