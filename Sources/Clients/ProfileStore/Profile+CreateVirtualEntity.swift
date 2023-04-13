import ClientPrelude
import Profile
import UseFactorSourceClient

extension Profile {
	public func createNewUnsavedVirtualEntity<Entity: EntityProtocol>(
		request: CreateVirtualEntityRequest
	) async throws -> Entity {
		try await self.createNewUnsavedVirtualEntity(
			request: request,
			entityKind: Entity.entityKind
		).cast()
	}

	public func createNewUnsavedVirtualEntity(
		request: CreateVirtualEntityRequest,
		entityKind: EntityKind
	) async throws -> any EntityProtocol {
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient

		let networkID = request.networkID ?? self.appPreferences.gateways.current.network.id
		let babylonDeviceFactorSource = request.babylonDeviceFactorSource
		let deviceFactorSourceStorage = babylonDeviceFactorSource.deviceStorage
		let index = deviceFactorSourceStorage.nextForEntity(kind: entityKind, networkID: networkID)
		let derivationPath = try DerivationPath.forEntity(kind: entityKind, networkID: networkID, index: index)

		let genesisFactorInstance: FactorInstance = try await {
			let publicKey = try await useFactorSourceClient.publicKeyFromOnDeviceHD(
				.init(
					hdOnDeviceFactorSource: babylonDeviceFactorSource.hdOnDeviceFactorSource,
					derivationPath: derivationPath,
					curve: request.curve,
					creationOfEntity: entityKind
				)
			)

			return try FactorInstance(
				factorSourceID: babylonDeviceFactorSource.id,
				publicKey: .init(engine: publicKey),
				derivationPath: derivationPath
			)
		}()

		let displayName = request.displayName
		let unsecuredControl = UnsecuredEntityControl(
			genesisFactorInstance: genesisFactorInstance
		)

		switch entityKind {
		case .identity:
			let identityAddress = try Profile.Network.Persona.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)

			let persona = Profile.Network.Persona(
				networkID: networkID,
				address: identityAddress,
				securityState: .unsecured(unsecuredControl),
				displayName: displayName,
				fields: .init()
			)
			return persona
		case .account:
			let accountAddress = try Profile.Network.Account.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)
			let index = (try? self.network(id: networkID))?.accounts.count ?? 0
			let appearanceID = Profile.Network.Account.AppearanceID.fromIndex(index)
			let account = Profile.Network.Account(
				networkID: networkID,
				address: accountAddress,
				securityState: .unsecured(unsecuredControl),
				appearanceID: appearanceID,
				displayName: displayName
			)
			return account
		}
	}
}
