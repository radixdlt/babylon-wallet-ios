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
	enum Root: Equatable {
		public typealias InitialState = NameNewEntity.State
		case nameNewEntity(NameNewEntity.State)
		case selectGenesisFactorSource(SelectGenesisFactorSource.State)
		case completion(CompletionState)

		public init(state: InitialState = .init()) {
			self = .nameNewEntity(state)
		}
	}
}
