import ComposableArchitecture

// MARK: - NameShield
@Reducer
struct NameShield: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder

		var inputtedName = ""
		var sanitizedName: NonEmptyString?
		var textFieldFocused = true
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case textFieldChanged(String)
		case focusChanged(Bool)
		case confirmButtonTapped(NonEmptyString)
	}

	enum DelegateAction: Equatable, Sendable {
		case finished
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmingWhitespace())
			return .none

		case let .focusChanged(value):
			state.textFieldFocused = value
			return .none

		case let .confirmButtonTapped(name):
			state.$shieldBuilder.withLock { builder in
				builder = builder.setName(name: name.rawValue)
			}
			return .run { [shieldBuilder = state.shieldBuilder] send in
				let shield = try shieldBuilder.build()
				try await SargonOs.shared.addSecurityStructureOfFactorSourceIds(structureIds: shield)
				await send(.delegate(.finished))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}
}
