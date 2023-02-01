import FeaturePrelude

// MARK: - CreateEntityCoordinator.State
public extension CreateEntityCoordinator {
	struct State: Equatable {
		public enum Step: Equatable {
			case nameNewEntity(NameNewEntity.State)
			case selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case completion(CompletionState)
		}

		public let step: Step
		public let config: StateConfig
		public let completionDestination: CompletionState.Destination
		public let canBeDismissed: Bool

		public init(
			step: Step,
			canBeDismissed: Bool = true,
			config: StateConfig,
			completionDestination: CompletionState.Destination
		) {
			self.canBeDismissed = canBeDismissed
			self.step = step
			self.completionDestination = completionDestination
			self.config = config
		}
	}
}
