import CryptoKit
import Dependencies
import EngineToolkit
import EngineToolkitClient
import KeychainClientDependency
import Prelude
import Profile
import SLIP10
import UserDefaultsClient

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
				let networkAndGateway = request.networkAndGateway

				let newProfile = try await Profile.new(
					networkAndGateway: networkAndGateway,
					mnemonic: request.curve25519FactorSourceMnemonic,
					firstAccountDisplayName: request.nameOfFirstAccount
				)

				return newProfile
			},
			injectProfile: { profile in
				try await profileHolder.injectProfile(profile)
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
			createVirtualAccount: { request in
				try await profileHolder.asyncMutating { profile in
					let networkID = await getCurrentNetworkID()
					return try await profile.createNewVirtualAccount(
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

	func injectProfile(_ profile: Profile) async throws {
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
