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
		let factorSource = request.factorSource
		let deviceFactorSourceStorage = try factorSource.deviceStorage()
		let index = deviceFactorSourceStorage.nextForEntity(kind: entityKind, networkID: networkID)
		let derivationPath = try DerivationPath.forEntity(kind: entityKind, networkID: networkID, index: index)

		let genesisFactorInstance: FactorInstance = try await {
//			let publicKey: Engine.PublicKey = try await useFactorSourceClient.onDeviceHD(
//				factorSourceID: factorSource.id,
//				derivationPath: derivationPath,
//				curve: request.curve,
//				purpose: .createEntity(kind: entityKind)
//			).publicKey
			let publicKey = try await useFactorSourceClient.publicKeyFromOnDeviceHD(.init(factorSource: factorSource, derivationPath: derivationPath, curve: request.curve, creationOfEntity: entityKind))

			return try FactorInstance(
				factorSourceID: factorSource.id,
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
			let identityAddress = try OnNetwork.Persona.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)

			let persona = OnNetwork.Persona(
				networkID: networkID,
				address: identityAddress,
				securityState: .unsecured(unsecuredControl),
				displayName: displayName,
				fields: .init()
			)
			return persona
		case .account:
			let accountAddress = try OnNetwork.Account.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)
			let index = (try? self.onNetwork(id: networkID))?.accounts.count ?? 0
			let appearanceID = OnNetwork.Account.AppearanceID.fromIndex(index)
			let account = OnNetwork.Account(
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
