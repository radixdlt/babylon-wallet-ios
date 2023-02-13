import ClientPrelude
import Cryptography
import EngineToolkitClient
import ProfileClient

// MARK: - ProfileClient + DependencyKey
extension ProfileClient: DependencyKey {}

// MARK: - ProfileClient + LiveValue
extension ProfileClient {
	public static let liveValue: Self = {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		let profileHolder = ProfileHolder.shared

		let getAppPreferences: GetAppPreferences = {
			try await profileHolder.get { profile in
				profile.appPreferences
			}
		}

		let getNetworkAndGateway: GetNetworkAndGateway = {
			do {
				return try await getAppPreferences().networkAndGateway
			} catch {
				return AppPreferences.NetworkAndGateway.nebunet
			}
		}

		let getCurrentNetworkID: GetCurrentNetworkID = {
			await getNetworkAndGateway().network.id
		}

		let getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL = {
			await getNetworkAndGateway().gatewayAPIEndpointURL
		}

		let lookupAccountByAddress: LookupAccountByAddress = { accountAddress in
			// Get default NetworkID
			let networkID = await getCurrentNetworkID()
			return try await profileHolder.get { profile in
				guard let account = try profile.entity(networkID: networkID, address: accountAddress) as? OnNetwork.Account else {
					throw ExpectedEntityToBeAccount()
				}
				return account
			}
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { networkID in
			try await profileHolder.get { profile in
				profile.containsNetwork(withID: networkID)
			}
		}

		let getDerivationPathForNewEntity: GetDerivationPathForNewEntity = { request in
			let networkID: NetworkID = await {
				if let networkID = request.networkID {
					return networkID
				}
				return await getCurrentNetworkID()
			}()

			return try await profileHolder.getAsync { profile in
				let index: Int = {
					if let network = try? profile.onNetwork(id: networkID) {
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
				case .account: return try (path: DerivationPath.accountPath(.init(networkID: networkID, index: index, keyKind: request.keyKind)), index: index)
				case .identity: return try (path: DerivationPath.identityPath(.init(networkID: networkID, index: index, keyKind: request.keyKind)), index: index)
				}
			}
		}

		return Self(
			getFactorSources: {
				try await profileHolder.getAsync { $0.factorSources }
			},
			getCurrentNetworkID: getCurrentNetworkID,
			getGatewayAPIEndpointBaseURL: getGatewayAPIEndpointBaseURL,
			getNetworkAndGateway: getNetworkAndGateway,
			setNetworkAndGateway: { networkAndGateway in
				try await profileHolder.asyncMutating { profile in
					// Ensure we have accounts on network, else do not change
					_ = try profile.onNetwork(id: networkAndGateway.network.id)
					profile.appPreferences.networkAndGateway = networkAndGateway
				}
			},
			createEphemeralProfileAndUnsavedOnDeviceFactorSource: { request in
				@Dependency(\.mnemonicClient.generate) var generateMnemonic

				let mnemonic = try generateMnemonic(request.wordCount, request.language)

				let newProfile = try await Profile.new(
					networkAndGateway: request.networkAndGateway,
					mnemonic: mnemonic
				)

				// This new profile is marked as "ephemeral" which means it is
				// not allowed to be persisted to keychain.
				await profileHolder.injectProfile(newProfile, isEphemeral: true)

				return CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse(request: request, mnemonic: mnemonic, profile: newProfile)
			},
			injectProfileSnapshot: { snapshot in
				let profile = try Profile(snapshot: snapshot)
				try await keychainClient.updateProfileSnapshot(profileSnapshot: snapshot)
				await profileHolder.injectProfile(profile, isEphemeral: false)
			},
			commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic: { request in

				let mnemonic = request.onDeviceFactorSourceMnemonic

				// FIXME: Cleanup post Betanet v2 when we have the new FactorSource format.
				let expectedFactorSourceID = try HD.Root(
					seed: mnemonic.seed(passphrase: request.bip39Passphrase)
				).factorSourceID(
					curve: Curve25519.self
				)

				try await profileHolder.getAsync { profile in
					let factorSource = profile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first
					guard factorSource.factorSourceID == expectedFactorSourceID else {
						struct DiscrepancyMismatchingFactorSourceIDs: Swift.Error {}
						throw DiscrepancyMismatchingFactorSourceIDs()
					}
					// all good
					try await keychainClient.updateFactorSource(
						mnemonic: mnemonic,
						reference: factorSource.reference
					)
				}

				try await profileHolder.persistAndAllowFuturePersistenceOfEphemeralProfile()

			},
			loadProfile: {
				@Dependency(\.jsonDecoder) var jsonDecoder

				guard
					let profileSnapshotData = try? await keychainClient
					.loadProfileSnapshotJSONData(
						// This should not be be shown due to settings of profile snapshot
						// item when it was originally stored.
						authenticationPrompt: "Load accounts"
					)
				else {
					return .success(nil)
				}

				let decodedVersion: ProfileSnapshot.Version
				do {
					decodedVersion = try ProfileSnapshot.Version.fromJSON(
						data: profileSnapshotData,
						jsonDecoder: jsonDecoder()
					)
				} catch {
					return .failure(
						.decodingFailure(
							json: profileSnapshotData,
							.known(.noProfileSnapshotVersionFoundInJSON
							)
						)
					)
				}

				do {
					try ProfileSnapshot.validateCompatability(version: decodedVersion)
				} catch {
					// Incompatible Versions
					return .failure(.profileVersionOutdated(
						json: profileSnapshotData,
						version: decodedVersion
					))
				}

				let profileSnapshot: ProfileSnapshot
				do {
					profileSnapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData)
				} catch let decodingError as Swift.DecodingError {
					return .failure(.decodingFailure(
						json: profileSnapshotData,
						.known(.decodingError(.init(decodingError: decodingError)))
					)
					)
				} catch {
					return .failure(.decodingFailure(
						json: profileSnapshotData,
						.unknown(.init(error: error))
					))
				}

				let profile: Profile
				do {
					profile = try Profile(snapshot: profileSnapshot)
				} catch {
					return .failure(.failedToCreateProfileFromSnapshot(
						.init(
							version: profileSnapshot.version,
							error: error
						))
					)
				}

				await profileHolder.injectProfile(profile, isEphemeral: false)
				return .success(profile)
			},
			extractProfileSnapshot: {
				try await profileHolder.takeProfileSnapshot()
			},
			deleteProfileAndFactorSources: {
				do {
					try await keychainClient.removeAllFactorSourcesAndProfileSnapshot(
						// This should not be be shown due to settings of profile snapshot
						// item when it was originally stored.
						authenticationPrompt: "Read wallet data in order get reference to secret's to delete"
					)
				} catch {
					try await keychainClient.removeProfileSnapshot()
				}
				await profileHolder.removeProfile()
			},
			hasAccountOnNetwork: hasAccountOnNetwork,
			getAccounts: {
				let currentNetworkID = await getCurrentNetworkID()
				return try await profileHolder.get { profile in
					let onNetwork = try profile.perNetwork.onNetwork(id: currentNetworkID)
					return onNetwork.accounts
				}
			},
			getPersonas: {
				let currentNetworkID = await getCurrentNetworkID()
				return try await profileHolder.get { profile in
					let onNetwork = try profile.perNetwork.onNetwork(id: currentNetworkID)
					return onNetwork.personas
				}
			},
			getP2PClients: {
				try await profileHolder.get { profile in
					profile.appPreferences.p2pClients
				}
			},
			getConnectedDapps: {
				let currentNetworkID = await getCurrentNetworkID()
				return try await profileHolder.get { profile in
					let onNetwork = try profile.perNetwork.onNetwork(id: currentNetworkID)
					return onNetwork.connectedDapps
				}
			},
			addConnectedDapp: { connectedDapp in
				try await profileHolder.asyncMutating { profile in
					_ = try await profile.addConnectedDapp(connectedDapp)
				}
			},
			detailsForConnectedDapp: { connectedDappSimple in
				try await profileHolder.get { profile in
					try profile.detailsForConnectedDapp(connectedDappSimple)
				}
			},
			updateConnectedDapp: { updated in
				try await profileHolder.asyncMutating { profile in
					try await profile.updateConnectedDapp(updated)
				}
			},
			addP2PClient: { newClient in
				try await profileHolder.asyncMutating { profile in
					_ = profile.appendP2PClient(newClient)
				}
			},
			deleteP2PClientByID: { id in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.p2pClients.clients.removeAll(where: { $0.id == id })
				}
			},
			getAppPreferences: getAppPreferences,
			setDisplayAppPreferences: { newDisplayPreferences in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.display = newDisplayPreferences
				}
			},
			createUnsavedVirtualEntity: { request in
				let networkID: NetworkID = await {
					if let networkID = request.networkID {
						return networkID
					}
					return await getCurrentNetworkID()
				}()
				let getDerivationPathRequest = try request.getDerivationPathRequest()
				let (derivationPath, index) = try await getDerivationPathForNewEntity(getDerivationPathRequest)

				let genesisFactorInstance: FactorInstance = try await {
					let genesisFactorInstanceDerivationStrategy = request.genesisFactorInstanceDerivationStrategy
					let mnemonic: Mnemonic
					let factorSource = genesisFactorInstanceDerivationStrategy.factorSource
					switch genesisFactorInstanceDerivationStrategy {
					case .loadMnemonicFromKeychainForFactorSource:
						guard let loadedMnemonic = try await keychainClient.loadFactorSourceMnemonic(
							reference: factorSource.reference,
							authenticationPrompt: request.keychainAccessFactorSourcesAuthPrompt
						) else {
							struct FailedToFindFactorSource: Swift.Error {}
							throw FailedToFindFactorSource()
						}
						mnemonic = loadedMnemonic
					case let .useMnemonic(unsavedMnemonic, _):
						mnemonic = unsavedMnemonic
					}

					let genesisFactorInstanceResponse = try await factorSource.createAnyFactorInstanceForResponse(
						input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput(
							mnemonic: mnemonic,
							derivationPath: derivationPath,
							includePrivateKey: false
						)
					)
					return genesisFactorInstanceResponse.factorInstance
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

					let persona = try OnNetwork.Persona(
						networkID: networkID,
						address: identityAddress,
						securityState: .unsecured(unsecuredControl),
						index: index,
						derivationPath: derivationPath.asIdentityPath(),
						displayName: displayName,
						fields: .init()
					)
					return persona
				case .account:
					let accountAddress = try OnNetwork.Account.deriveAddress(
						networkID: networkID,
						publicKey: genesisFactorInstance.publicKey
					)

					let account = try OnNetwork.Account(
						networkID: networkID,
						address: accountAddress,
						securityState: .unsecured(unsecuredControl),
						index: index,
						derivationPath: derivationPath.asAccountPath(),
						displayName: displayName
					)
					return account
				}
			},
			addAccount: { account in
				try await profileHolder.asyncMutating { profile in
					try await profile.addAccount(account)
				}
			},
			addPersona: { persona in
				try await profileHolder.asyncMutating { profile in
					try await profile.addPersona(persona)
				}
			},
			lookupAccountByAddress: lookupAccountByAddress,
			signersForAccountsGivenAddresses: { request in

				let mnemonicForFactorSourceByReference: MnemonicForFactorSourceByReference = { reference in
					try await keychainClient.loadFactorSourceMnemonic(
						reference: reference,
						authenticationPrompt: request.keychainAccessFactorSourcesAuthPrompt
					)
				}

				func getAccountSignersFromAddresses() async throws -> NonEmpty<OrderedSet<SignersOfAccount>>? {
					guard let addresses = NonEmpty(rawValue: request.addresses) else { return nil }

					let accounts = try await addresses.asyncMap { try await lookupAccountByAddress($0) }

					return try await profileHolder.getAsync { profile in
						try await profile.signers(
							ofEntities: accounts,
							mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference
						)
					}
				}

				guard let fromAddresses = try? await getAccountSignersFromAddresses() else {
					// TransactionManifest does not reference any accounts => use any account!
					return try await profileHolder.getAsync { profile in
						try await profile.signers(
							networkID: request.networkID,
							entityType: OnNetwork.Account.self,
							entityIndex: 0,
							mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference
						)
					}
				}
				return fromAddresses
			}
		)
	}()
}

// MARK: - ExpectedEntityToBeAccount
struct ExpectedEntityToBeAccount: Swift.Error {}

// MARK: - FoundNoSignersForAccounts
struct FoundNoSignersForAccounts: Swift.Error {}

// MARK: - NoProfile
struct NoProfile: Swift.Error {}

// MARK: - ProfileHolder
private actor ProfileHolder: GlobalActor {
	@Dependency(\.keychainClient) var keychainClient

	/// If this is set to `true` it means that any edits of the profile should not be persisted at all
	/// this is used for convenience of implementation of Onboarding flow where we create an ephemeral
	/// profile which should only be persisted at the end of Onboarding flow. Letting this ephemeral
	/// profile live here (in stored property `profile`) allows us to use the same APIs as if it would
	/// have not been ephemeral, and at the
	private var isEphemeral: Bool = false
	private var profile: Profile?

	private init() {}
	fileprivate static let shared = ProfileHolder()

	func removeProfile() {
		profile = nil
	}

	@discardableResult
	func get<T>(_ withProfile: @Sendable (Profile) throws -> T) throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try withProfile(profile)
	}

	@discardableResult
	func getAsync<T>(_ withProfile: @Sendable (Profile) async throws -> T) async throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try await withProfile(profile)
	}

	func persistAndAllowFuturePersistenceOfEphemeralProfile() async throws {
		isEphemeral = false
		try await persistProfileIfAllowed()
	}

	// if profile is marked as "ephemeral" we will not persist.
	// Async because we might wanna add iCloud sync here in future.
	private func persistProfileIfAllowed() async throws {
		guard !isEphemeral else { return }
		let profileSnapshot = try takeProfileSnapshot()
		try await keychainClient.updateProfileSnapshot(profileSnapshot: profileSnapshot)
	}

	func asyncMutating<T>(_ mutateProfile: @Sendable (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await mutateProfile(&profile)
		self.profile = profile
		// if profile is marked as "ephemeral" we will not persist.
		try await persistProfileIfAllowed()
		return result
	}

	func injectProfile(_ profile: Profile, isEphemeral: Bool) async {
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
