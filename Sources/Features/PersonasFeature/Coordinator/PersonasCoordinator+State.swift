import CreateEntityFeature
import FeaturePrelude

// MARK: - PersonasCoordinator.State
extension PersonasCoordinator {
	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		public var createPersonaCoordinator: CreatePersonaCoordinator.State?

		public init(
			personaList: PersonaList.State = .init(),
			createPersonaCoordinator: CreatePersonaCoordinator.State? = nil
		) {
			self.personaList = personaList
			self.createPersonaCoordinator = createPersonaCoordinator
		}
	}
}

#if DEBUG
extension PersonasCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
