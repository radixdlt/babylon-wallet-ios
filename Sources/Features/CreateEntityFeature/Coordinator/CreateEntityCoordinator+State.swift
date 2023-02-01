import FeaturePrelude

// MARK: - CreateEntityCoordinator.State
public extension CreateEntityCoordinator {
	struct State: Equatable {
		public enum Step: Equatable {
			case step0_nameNewEntity(NameNewEntity<Entity>.State)
			case step1_selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(CompletionState)
		}

		public var step: Step
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
