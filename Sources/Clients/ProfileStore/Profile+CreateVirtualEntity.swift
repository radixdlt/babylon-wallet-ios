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
		let (derivationPath, index) = try {
			let index: Int = {
				// FIXME: - Multifactor, in the future update to:
				// We are NOT counting the number of accounts/personas
				// and returning the next index. We returning index
				// for this particular factor source on this particular
				// network for this particular entity type.
				if let network = try? self.onNetwork(id: networkID) {
					switch entityKind {
					case .account:
						return network.accounts.count
					case .identity:
						return network.personas.count
					}
				} else {
					return 0
				}
			}()
			let keyKind = KeyKind.virtualEntity
			switch entityKind {
			case .account:
				let path = try DerivationPath.accountPath(.init(networkID: networkID, index: index, keyKind: keyKind))
				return (path: path, index: index)
			case .identity:
				let path = try DerivationPath.identityPath(.init(networkID: networkID, index: index, keyKind: keyKind))
				return (path: path, index: index)
			}
		}()

		let genesisFactorInstance: FactorInstance = try await {
			let factorSource = request.factorSource
			let publicKey: Engine.PublicKey = try await useFactorSourceClient.onDeviceHD(
				factorSourceID: factorSource.id,
				derivationPath: derivationPath,
				curve: request.curve,
				purpose: .createEntity(kind: entityKind)
			).publicKey

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

			let account = OnNetwork.Account(
				networkID: networkID,
				address: accountAddress,
				securityState: .unsecured(unsecuredControl),
				appearanceID: .fromIndex(index),
				displayName: displayName
			)
			return account
		}
	}
}
