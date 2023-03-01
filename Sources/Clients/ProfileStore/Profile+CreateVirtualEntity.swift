import ClientPrelude
import Profile
import UseFactorSourceClient

extension Profile {
	public func createUnsavedVirtualEntity<Entity: EntityProtocol>(
		request: CreateVirtualEntityRequestProtocol
	) async throws -> Entity {
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient

		//        let networkID: NetworkID = await {
		//            if let networkID = request.networkID {
		//                return networkID
		//            }
		//            return await getCurrentNetworkID()
		//        }()
		let networkID = request.networkID ?? self.network.networkID
		let getDerivationPathRequest = try request.getDerivationPathRequest()
		let getDerivationPathForNewEntity = { (request: GetDerivationPathForNewEntityRequest) async throws -> (path: DerivationPath, index: Int) in

			let index: Int = {
				// FIXME: - Multifactor, in the future update to:
				// We are NOT counting the number of accounts/personas
				// and returning the next index. We returning index
				// for this particular factor source on this particular
				// network for this particular entity type.
				if let network = try? self.onNetwork(id: networkID) {
					switch request.entityKind {
					case .account:
						return network.accounts.count
					case .identity:
						return network.personas.count
					}
				} else {
					return 0
				}
			}()

			switch request.entityKind {
			case .account:
				let path = try DerivationPath.accountPath(.init(networkID: networkID, index: index, keyKind: request.keyKind))
				return (path: path, index: index)
			case .identity:
				let path = try DerivationPath.identityPath(.init(networkID: networkID, index: index, keyKind: request.keyKind))
				return (path: path, index: index)
			}
		}
		let (derivationPath, index) = try await getDerivationPathForNewEntity(getDerivationPathRequest)

		let genesisFactorInstance: FactorInstance = try await {
			let genesisFactorInstanceDerivationStrategy = request.genesisFactorInstanceDerivationStrategy

			let factorSource = genesisFactorInstanceDerivationStrategy.factorSource
			let publicKey: Engine.PublicKey = try await {
				switch genesisFactorInstanceDerivationStrategy {
				case .loadMnemonicFromKeychainForFactorSource:
					return try await useFactorSourceClient.onDeviceHD(
						factorSourceID: factorSource.id,
						derivationPath: derivationPath,
						curve: request.curve,
						purpose: .createEntity(kind: request.entityKind)
					).publicKey

				case let .useEphemeralPrivateProfile(ephemeralPrivateProfile):
					let hdRoot = try ephemeralPrivateProfile.privateFactorSource.mnemonicWithPassphrase.hdRoot()
					return try useFactorSourceClient.publicKeyFromOnDeviceHD(.init(
						hdRoot: hdRoot,
						derivationPath: derivationPath,
						curve: request.curve
					))
				}

			}()

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

		switch request.entityKind {
		case .identity:
			let identityAddress = try OnNetwork.Persona.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)

			let persona = OnNetwork.Persona(
				networkID: networkID,
				address: identityAddress,
				securityState: .unsecured(unsecuredControl),
				index: index,
				displayName: displayName,
				fields: .init()
			)
			return persona as! Entity
		case .account:
			let accountAddress = try OnNetwork.Account.deriveAddress(
				networkID: networkID,
				publicKey: genesisFactorInstance.publicKey
			)

			let account = OnNetwork.Account(
				networkID: networkID,
				address: accountAddress,
				securityState: .unsecured(unsecuredControl),
				index: index,
				displayName: displayName
			)
			return account as! Entity
		}
	}
}
