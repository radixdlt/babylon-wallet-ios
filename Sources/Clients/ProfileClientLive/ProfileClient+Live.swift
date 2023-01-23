import ClientPrelude
import Cryptography
import EngineToolkitClient
import ProfileClient

// MARK: - ProfileClient + DependencyKey
extension ProfileClient: DependencyKey {}

// MARK: - ProfileClient + LiveValue
public extension ProfileClient {
	static let liveValue: Self = {
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
			createNewProfile: { request in

				@Dependency(\.mnemonicClient.generate) var generateMnemonic

				let mnemonic = try generateMnemonic(BIP39.WordCount.twentyFour, BIP39.Language.english)

				let networkAndGateway = AppPreferences.NetworkAndGateway.nebunet
				let newProfile = try await Profile.new(
					networkAndGateway: networkAndGateway,
					mnemonic: mnemonic,
					firstAccountDisplayName: request.nameOfFirstAccount
				)

				let factorSourceReference = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference

				try await keychainClient.updateFactorSource(
					mnemonic: mnemonic,
					reference: factorSourceReference
				)
				try await keychainClient.updateProfile(profile: newProfile)

				await profileHolder.injectProfile(newProfile)

				let accountOnCurrentNetwork = try newProfile.onNetwork(id: networkAndGateway.network.id).accounts.first

				return accountOnCurrentNetwork
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

				await profileHolder.injectProfile(profile)
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
			createUnsavedVirtualAccount: { request in
				try await profileHolder.getAsync { profile in
					let networkID = await getCurrentNetworkID()
					return try await profile.creatingNewVirtualAccount(
						networkID: request.overridingNetworkID ?? networkID,
						displayName: request.accountName,
						mnemonicForFactorSourceByReference: { [keychainClient] reference in
							try await keychainClient
								.loadFactorSourceMnemonic(
									reference: reference,
									authenticationPrompt: request.keychainAccessFactorSourcesAuthPrompt
								)
						}
					)
				}
			},
			createUnsavedVirtualPersona: { request in
				try await profileHolder.getAsync { profile in
					let networkID = await getCurrentNetworkID()
					return try await profile.creatingNewVirtualPersona(
						networkID: request.overridingNetworkID ?? networkID,
						displayName: request.personaName,
						fields: request.fields,
						mnemonicForFactorSourceByReference: { [keychainClient] reference in
							try await keychainClient
								.loadFactorSourceMnemonic(
									reference: reference,
									authenticationPrompt: request.keychainAccessFactorSourcesAuthPrompt
								)
						}
					)
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

	// Async because we might wanna add iCloud sync here in future.
	private func persistProfile() async throws {
		let profileSnapshot = try takeProfileSnapshot()
		try await keychainClient.updateProfileSnapshot(profileSnapshot: profileSnapshot)
	}

	func asyncMutating<T>(_ mutateProfile: @Sendable (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await mutateProfile(&profile)
		self.profile = profile
		try await persistProfile()
		return result
	}

	func injectProfile(_ profile: Profile) async {
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
