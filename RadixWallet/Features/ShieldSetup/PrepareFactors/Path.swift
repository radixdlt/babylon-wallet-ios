// MARK: - PrepareFactors.Coordinator
extension PrepareFactors {
	@Reducer
	struct Path: Sendable {
		@ObservableState
		@CasePathable
		enum State: Sendable, Hashable {
			case intro
			case addFactor(PrepareFactors.AddFactor.State)
			case completion
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case introFinished
			case addFactor(PrepareFactors.AddFactor.Action)
			case completionFinished
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addFactor, action: \.addFactor) {
				PrepareFactors.AddFactor()
			}
		}
	}
}
