import ClientPrelude
import Cryptography
import EngineToolkitClient
import ProfileClient
import SecureStorageClient
import UseFactorSourceClient

// MARK: - ProfileClient + DependencyKey
extension ProfileClient: DependencyKey {}

// MARK: - ProfileClient + LiveValue
extension ProfileClient {
	public static let liveValue: Self = {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.secureStorageClient) var secureStorageClient
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

		let getAccountsOnNetwork: GetAccountsOnNetwork = { networkID in
			try await profileHolder.get { profile in
				let onNetwork = try profile.perNetwork.onNetwork(id: networkID)
				return onNetwork.accounts
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
					// FIXME: - Multifactor, in the future update to:
					// We are NOT counting the number of accounts/personas
					// and returning the next index. We returning index
					// for this particular factor source on this particular
					// network for this particular entity type.
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
				case .account:
					let path = try DerivationPath.accountPath(.init(networkID: networkID, index: index, keyKind: request.keyKind))
					return (path: path, index: index)
				case .identity:
					let path = try DerivationPath.identityPath(.init(networkID: networkID, index: index, keyKind: request.keyKind))
					return (path: path, index: index)
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
			createOnboardingWallet: { request in
				@Dependency(\.mnemonicClient.generate) var generateMnemonic

				let bip39Passphrase = request.bip39Passphrase
				let mnemonic = try generateMnemonic(request.wordCount, request.language)
				let mnemonicAndPassphrase = MnemonicWithPassphrase(
					mnemonic: mnemonic,
					passphrase: bip39Passphrase
				)
				let onDeviceFactorSource = try await FactorSource.babylon(
					mnemonic: mnemonic,
					bip39Passphrase: bip39Passphrase
				)
				let privateFactorSource = try PrivateHDFactorSource(
					mnemonicWithPassphrase: mnemonicAndPassphrase,
					factorSource: onDeviceFactorSource
				)

				let profile = Profile(factorSource: onDeviceFactorSource)

				// This new profile is marked as "ephemeral" which means it is
				// not allowed to be persisted to keychain.
				await profileHolder.injectProfile(profile, isEphemeral: true)

				return OnboardingWallet(privateFactorSource: privateFactorSource, profile: profile)
			},
			injectProfileSnapshot: { snapshot in
				let profile = try Profile(snapshot: snapshot)
				try await secureStorageClient.addNewProfileSnapshot(snapshot)
				await profileHolder.injectProfile(profile, isEphemeral: false)
			},
			commitOnboardingWallet: { request in
				try await profileHolder.getAsync { profile in
					guard profile.id == request.profile.id else {
						struct DiscrepancyMismatchingProfileID: Swift.Error {}
						throw DiscrepancyMismatchingProfileID()
					}

					// all good
					try await secureStorageClient.addNewMnemonicForFactorSource(request.privateFactorSource)
				}

				try await profileHolder.persistAndAllowFuturePersistenceOfEphemeralProfile()

			},
			loadProfile: {
				@Dependency(\.jsonDecoder) var jsonDecoder

				guard
					let profileSnapshotData = try? await secureStorageClient.loadProfileSnapshotData()
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
				try? await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs()
				await profileHolder.removeProfile()
			},
			hasAccountOnNetwork: hasAccountOnNetwork,
			getAccountsOnNetwork: getAccountsOnNetwork,
			getAccounts: {
				let currentNetworkID = await getCurrentNetworkID()
				return try await getAccountsOnNetwork(currentNetworkID)
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
					_ = try profile.addConnectedDapp(connectedDapp)
				}
			},
			detailsForConnectedDapp: { connectedDappSimple in
				try await profileHolder.get { profile in
					try profile.detailsForConnectedDapp(connectedDappSimple)
				}
			},
			updateConnectedDapp: { updated in
				try await profileHolder.asyncMutating { profile in
					try profile.updateConnectedDapp(updated)
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
				@Dependency(\.useFactorSourceClient) var useFactorSourceClient

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

						case let .useOnboardingWallet(onboardingWallet):
							let hdRoot = try onboardingWallet.privateFactorSource.mnemonicWithPassphrase.hdRoot()
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
						index: index,
						displayName: displayName
					)
					return account
				}
			},
			addAccount: { account in
				try await profileHolder.asyncMutating { profile in
					try profile.addAccount(account)
				}
			},
			addPersona: { persona in
				try await profileHolder.asyncMutating { profile in
					try profile.addPersona(persona)
				}
			},
			lookupAccountByAddress: lookupAccountByAddress
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
	@Dependency(\.secureStorageClient) var secureStorageClient

	/// If this is set to `true` it means that any edits of the profile should not be persisted at all
	/// this is used for convenience of implementation of Onboarding flow where we create an ephemeral
	/// profile which should only be persisted at the end of Onboarding flow. Letting this ephemeral
	/// profile live here (in stored property `profile`) allows us to use the same APIs as if it would
	/// have not been ephemeral, and at the
	private var isEphemeral: Bool = true
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
		try await persistProfileIfAllowed(isNew: true)
	}

	// if profile is marked as "ephemeral" we will not persist.
	// Async because we might wanna add iCloud sync here in future.
	private func persistProfileIfAllowed(isNew: Bool) async throws {
		guard !isEphemeral else { return }
		let profileSnapshot = try takeProfileSnapshot()
		if isNew {
			try await secureStorageClient.addNewProfileSnapshot(profileSnapshot)
		} else {
			try await secureStorageClient.updateProfileSnapshot(profileSnapshot)
		}
	}

	func asyncMutating<T>(_ mutateProfile: @Sendable (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await mutateProfile(&profile)
		self.profile = profile
		// if profile is marked as "ephemeral" we will not persist.
		try await persistProfileIfAllowed(isNew: false)
		return result
	}

	func injectProfile(_ profile: Profile, isEphemeral: Bool) async {
		self.isEphemeral = isEphemeral
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
