import Collections
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import KeychainClientDependency
import NonEmpty
import Profile
import SLIP10
import URLBuilderClient
import UserDefaultsClient

// MARK: - ProfileClient + LiveValue
public extension ProfileClient {
	static let liveValue: Self = {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.urlBuilder) var urlBuilder

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
				return AppPreferences.NetworkAndGateway.primary
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

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			getGatewayAPIEndpointBaseURL: getGatewayAPIEndpointBaseURL,
			getNetworkAndGateway: getNetworkAndGateway,
			setNetworkAndGateway: { networkAndGateway in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.networkAndGateway = networkAndGateway
				}
			},
			createNewProfileWithOnLedgerAccount: { request, makeAccountNonVirtual in

				let newProfile = try await Profile.new(
					networkAndGateway: .primary,
					mnemonic: request.curve25519FactorSourceMnemonic,
					firstAccountDisplayName: request.createFirstAccountRequest.accountName,
					makeFirstAccountNonVirtualBySubmittingItToLedger: makeAccountNonVirtual(request.createFirstAccountRequest)
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
					try keychainClient.removeAllFactorSourcesAndProfileSnapshot()
				} catch {
					try keychainClient.removeProfileSnapshot()
				}
				await profileHolder.removeProfile()
			},
			getAccounts: {
				try await profileHolder.get { profile in
					profile.primaryNet.accounts
				}
			},
			getP2PClients: {
				try await profileHolder.get { profile in
					profile.appPreferences.p2pClients
				}
			},
			addP2PClient: { newConnection in
				try await profileHolder.asyncMutating { profile in
					_ = profile.appPreferences.p2pClients.connections.append(newConnection)
				}
			},
			deleteP2PClientByID: { id in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.p2pClients.connections.removeAll(where: { $0.id == id })
				}
			},
			getAppPreferences: getAppPreferences,
			setDisplayAppPreferences: { newDisplayPreferences in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.display = newDisplayPreferences
				}
			},
			createOnLedgerAccount: { createAccountRequest, makeAccountNonVirtual in
				try await profileHolder.asyncMutating { profile in

					try await profile.createNewOnLedgerAccount(
						networkID: getCurrentNetworkID(),
						displayName: createAccountRequest.accountName,
						makeEntityNonVirtualBySubmittingItToLedger: makeAccountNonVirtual(createAccountRequest),
						mnemonicForFactorSourceByReference: { [keychainClient] reference in
							try keychainClient.loadFactorSourceMnemonic(reference: reference)
						}
					)
				}
			},
			lookupAccountByAddress: lookupAccountByAddress,
			privateKeysForAddresses: { addresses in
				// FIXME: betanet fix me
				let accounts = try await addresses.asyncMap { try await lookupAccountByAddress($0) }

				let matrix: [Set<PrivateKey>] = try await profileHolder.getAsync { profile -> [Set<PrivateKey>] in
					try await accounts.asyncMap { account -> Set<PrivateKey> in
						try await profile.withPrivateKeys(
							of: account,
							mnemonicForFactorSourceByReference: { [keychainClient] reference in
								try keychainClient.loadFactorSourceMnemonic(reference: reference)
							}
						) { (keys: NonEmpty<Set<PrivateKey>>) -> Set<PrivateKey> in
							keys.rawValue
						}
					}
				}
				var privateKeys = OrderedSet<PrivateKey>()
				matrix.forEach {
					privateKeys.append(contentsOf: $0)
				}

				guard let nonEmptyKeys = NonEmpty(rawValue: privateKeys) else {
					throw FoundNoKeysForAddresses()
				}
				return nonEmptyKeys
			}
		)
	}()
}

// MARK: - ExpectedEntityToBeAccount
struct ExpectedEntityToBeAccount: Swift.Error {}

// MARK: - FoundNoKeysForAddresses
struct FoundNoKeysForAddresses: Swift.Error {}

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
		try keychainClient.updateProfileSnapshot(profileSnapshot: profileSnapshot)
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
