import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var commitEphemeral: CommitEphemeral
	public var createNewUnsavedVirtualEntity: CreateNewUnsavedVirtualEntity
	public var saveNewVirtualEntity: SaveNewVirtualEntity
	public var importProfileSnapshot: ImportProfileSnapshot

	public init(
		loadProfile: @escaping LoadProfile,
		commitEphemeral: @escaping CommitEphemeral,
		createNewUnsavedVirtualEntity: @escaping CreateNewUnsavedVirtualEntity,
		saveNewVirtualEntity: @escaping SaveNewVirtualEntity,
		importProfileSnapshot: @escaping ImportProfileSnapshot
	) {
		self.loadProfile = loadProfile
		self.commitEphemeral = commitEphemeral
		self.createNewUnsavedVirtualEntity = createNewUnsavedVirtualEntity
		self.saveNewVirtualEntity = saveNewVirtualEntity
		self.importProfileSnapshot = importProfileSnapshot
	}
}

// MARK: - LoadProfileOutcome
public enum LoadProfileOutcome: Sendable, Hashable {
	case newUser
	case usersExistingProfileCouldNotBeLoaded(failure: Profile.LoadingFailure)
	case existingProfileLoaded
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> LoadProfileOutcome

	public typealias CommitEphemeral = @Sendable () async throws -> Void
	public typealias CreateNewUnsavedVirtualEntity = @Sendable (CreateVirtualEntityRequest) async throws -> some EntityProtocol
	public typealias SaveNewVirtualEntity = @Sendable (any EntityProtocol) async throws -> Void
	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
}

extension OnboardingClient {
	public func createNewUnsavedVirtualEntity<Entity: EntityProtocol>(
		request: CreateVirtualEntityRequestProtocol
	) async throws -> Entity {
		try await self.createNewUnsavedVirtualEntity(request).cast()
	}
}
