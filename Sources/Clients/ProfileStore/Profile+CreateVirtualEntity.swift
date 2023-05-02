import ClientPrelude
import Cryptography
import Profile
import UseFactorSourceClient

extension Profile {
	public func createNewUnsavedVirtualEntityControlledByDeviceFactorSource<Entity: EntityProtocol>(
		request: CreateVirtualEntityControlledByDeviceFactorSourceRequest
	) async throws -> Entity {
		try await self.createNewUnsavedVirtualEntityControlledByDeviceFactorSource(
			request: request,
			entityKind: Entity.entityKind
		).cast()
	}

	public func createNewUnsavedVirtualEntityControlledByDeviceFactorSource(
		request: CreateVirtualEntityControlledByDeviceFactorSourceRequest,
		entityKind: EntityKind
	) async throws -> any EntityProtocol {
		try await newUnsavedVirtualEntityControlledByDeviceFactorSource(
			request: request,
			entityType: entityKind.entityType
		)
	}

	public func newUnsavedVirtualEntityControlledByDeviceFactorSource<Entity: EntityProtocol>(
		request: CreateVirtualEntityControlledByDeviceFactorSourceRequest,
		entityType: Entity.Type
	) async throws -> Entity {
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient
		let entityKind = Entity.entityKind
		let networkID = request.networkID ?? self.appPreferences.gateways.current.network.id
		let babylonDeviceFactorSource = request.babylonDeviceFactorSource

		let index = babylonDeviceFactorSource
			.entityCreatingStorage
			.nextForEntity(kind: entityKind, networkID: networkID)

		let derivationPath = try DerivationPath.forEntity(
			kind: entityKind,
			networkID: networkID,
			index: index
		)

		let genesisFactorInstance: FactorInstance = try await {
			let publicKey = try await useFactorSourceClient.publicKeyFromOnDeviceHD(
				.init(
					hdOnDeviceFactorSource: babylonDeviceFactorSource.hdOnDeviceFactorSource,
					derivationPath: derivationPath,
					curve: .curve25519, // we always use Curve25519 for new accounts
					creationOfEntity: entityKind
				)
			)

			return try FactorInstance(
				factorSourceID: babylonDeviceFactorSource.id,
				publicKey: .init(engine: publicKey),
				derivationPath: derivationPath
			)
		}()

		let numberOfExistingEntities = {
			guard let network = (try? self.network(id: networkID)) else {
				return 0
			}
			switch entityKind {
			case .account: return network.accounts.count
			case .identity: return network.personas.count
			}
		}()

		return try Entity(
			networkID: networkID,
			factorInstance: genesisFactorInstance,
			displayName: request.displayName,
			extraProperties: request.extraProperties(numberOfExistingEntities).get(entityType: Entity.self)
		)
	}

	// FIXME: When MultiFactor remove this
	public func createNewUnsavedVirtualEntityControlledByLedgerFactorSource<Entity: EntityProtocol>(
		request: CreateVirtualEntityControlledByLedgerFactorSourceRequest
	) async throws -> Entity {
		let entityKind = Entity.entityKind
		let networkID = request.networkID ?? self.appPreferences.gateways.current.network.id
		let ledger = request.ledger
		let entityCreatingStorage = try ledger.entityCreatingStorage()
		let index = entityCreatingStorage.nextForEntity(kind: entityKind, networkID: networkID)
		let derivationPath = try DerivationPath.forEntity(kind: entityKind, networkID: networkID, index: index)

		let publicKey = try await request.derivePublicKey(derivationPath)
		let genesisFactorInstance = FactorInstance(factorSourceID: ledger.id, publicKey: .eddsaEd25519(publicKey), derivationPath: derivationPath)

		let numberOfExistingEntities = {
			guard let network = (try? self.network(id: networkID)) else {
				return 0
			}
			switch entityKind {
			case .account: return network.accounts.count
			case .identity: return network.personas.count
			}
		}()

		return try Entity(
			networkID: networkID,
			factorInstance: genesisFactorInstance,
			displayName: request.displayName,
			extraProperties: request.extraProperties(numberOfExistingEntities).get(entityType: Entity.self)
		)
	}
}
