import FeaturePrelude

// MARK: - CreateEntityCoordinator.State
public extension CreateEntityCoordinator {
	struct State: Equatable {
		public let completionDestination: CompletionState.Destination
		public var root: Root

		public init(
			completionDestination: CompletionState.Destination,
			rootState: Root.InitialState = .init()
		) {
			self.completionDestination = completionDestination
			self.root = .init(state: rootState)
		}
	}
}

// MARK: - CreateEntityCoordinator.State.Root
public extension CreateEntityCoordinator.State {
	struct Root: Equatable {
		public enum Mode: Equatable {}
		public enum Step: Equatable {
			case nameNewEntity(NameNewEntity.State)
			case selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case completion(CompletionState)
		}

		let mode: Mode
	}
}
