import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import KeychainClientDependency
import Profile
import SLIP10
import URLBuilderClient
import UserDefaultsClient

private let gatewayAPIEndpointURLStringKey = "gatewayAPIEndpointURLStringKey"

// MARK: - ProfileClient + DependencyKey
extension ProfileClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.urlBuilder) var urlBuilder

		let profileHolder = ProfileHolder.shared

		let getAppPreferences: GetAppPreferences = {
			try profileHolder.get { profile in
				profile.appPreferences
			}
		}

		let getNetworkAndGateway: () -> AppPreferences.NetworkAndGateway = {
			do {
				return try getAppPreferences().networkAndGateway
			} catch {
				return AppPreferences.NetworkAndGateway.primary
			}
		}

		let getCurrentNetworkID: GetCurrentNetworkID = {
			getNetworkAndGateway().network.id
		}

		let getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL = {
			getNetworkAndGateway().gatewayAPIEndpointURL
		}

		let setGatewayAPIEndpointURLByString: (String) async throws -> URL = { (newBaseURLString: String) async throws -> URL in
			// Flow is this:
			// 1. Try to build new URL from string
			// 2. Read currentURL
			// 3. Abort if newURL == currentURL
			// 4. Try to get network name (in future also ID?) from Gateway
			// 5. Lookup network ID by name (hardcoded lookup table)
			// 6. Abort if network ID is unknown
			// 7. Persist newURL in userDefaults

			// 1. Try to build new URL from string
			let newURL = try urlBuilder.urlFromString(newBaseURLString)
			// 2. Read currentURL
			let currentURL = getGatewayAPIEndpointBaseURL()
			// 3. Abort if newURL == currentURL
			guard newURL != currentURL else {
				return currentURL
			}

			/*
			 do {

			     let current = try await gatewayAPIClient.getCurrentBaseURL()
			     guard new != current else {
			         // Nothing to do!
			         return
			     }

			     try await gatewayAPIClient.setCurrentBaseURL()
			     // FIXME replace with getting network name once we have migrated to Enkinet/Hamunet
			     let hardCodedNetworkName = "Adapanet"
			     let networkNameGivenNewURL = hardCodedNetworkName

			     // 4. Lookup network ID based on network name
			     let networkID = try profileClient.lookupNetworkIDByNetworkName(hardCodedNetworkName)

			     // 5. Check if we need to create a new key value in Profile
			     if profileClient.getCurrentNetworkID() != networkID {
			         // 6. need to create new account on this new network and need to notify rest of app, and switch Gateway
			         try profileClient.setCurrentNetworkID(networkID)
			     } else {
			         // 6. No network switch needed, only need to switch Gateway
			     }
			 } catch {

			 }
			 */
			fatalError()
		}

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			getGatewayAPIEndpointBaseURL: getGatewayAPIEndpointBaseURL,
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
				try profileHolder.takeProfileSnapshot()
			},
			deleteProfileAndFactorSources: {
				do {
					try keychainClient.removeAllFactorSourcesAndProfileSnapshot()
				} catch {
					try keychainClient.removeProfileSnapshot()
				}
				profileHolder.removeProfile()
			},
			getAccounts: {
				try profileHolder.get { profile in
					profile.primaryNet.accounts
				}
			},
			getBrowserExtensionConnections: {
				try profileHolder.get { profile in
					profile.appPreferences.browserExtensionConnections
				}
			},
			addBrowserExtensionConnection: { newConnection in
				try await profileHolder.asyncMutating { profile in
					_ = profile.appPreferences.browserExtensionConnections.connections.append(newConnection)
				}
			},
			deleteBrowserExtensionConnection: { idOfConnectionToDelete in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.browserExtensionConnections.connections.removeAll(where: { $0.id == idOfConnectionToDelete })
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
			lookupAccountByAddress: { accountAddress in
				// Get default NetworkID
				let networkID = getCurrentNetworkID()
				return try profileHolder.get { profile in
					guard let account = try profile.entity(networkID: networkID, address: accountAddress) as? OnNetwork.Account else {
						throw ExpectedEntityToBeAccount()
					}
					return account
				}
			},
			signTransaction: { account, _ in
				try await profileHolder.getAsync { profile in
					try await profile.withPrivateKeys(
						of: account,
						mnemonicForFactorSourceByReference: { [keychainClient] reference in
							try keychainClient.loadFactorSourceMnemonic(reference: reference)
						}
					) { privateKeys in
						let privateKey = privateKeys.first
						fatalError()
//						print("🔏 Signing transaction and submitting to Ledger ✨")

//						let (_, txID) = try await gatewayAPIClient.submit(
//							pollStrategy: pollStrategy
//						) { epoch in
//
//							let signReq = BuildAndSignTransactionWithManifestRequest(
//								manifest: manifest,
//								privateKey: privateKey,
//								epoch: epoch,
//								networkID: getCurrentNetworkID()
//							)
//
//							return try engineToolkitClient.sign(request: signReq)
//						}

//						print("🔏 SUCCESSFULLY Signing transaction and submitting to Ledger ✅")
//						return txID
					}
				}
			}
		)
	}()
}

public extension ProfileClient {
	func signTransaction(
		manifest: TransactionManifest,
		addressOfSigner: AccountAddress
	) async throws -> TransactionIntent.TXID {
		let account = try lookupAccountByAddress(addressOfSigner)
		return try await signTransaction(account, manifest)
	}
}

// MARK: - ExpectedEntityToBeAccount
struct ExpectedEntityToBeAccount: Swift.Error {}

// MARK: - NoProfile
/// Used in GatewayClient as well
public struct NoProfile: Swift.Error {}

// MARK: - ProfileHolder
private final class ProfileHolder {
	@Dependency(\.keychainClient) var keychainClient
	private var profile: Profile?
	private init() {}
	fileprivate static let shared = ProfileHolder()

	func removeProfile() {
		profile = nil
	}

	@discardableResult
	func get<T>(_ withProfile: (Profile) throws -> T) throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try withProfile(profile)
	}

	@discardableResult
	func getAsync<T>(_ withProfile: (Profile) async throws -> T) async throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try await withProfile(profile)
	}

	// Async because we might wanna add iCloud sync here in future.
	private func persistProfile() async throws {
		let profileSnapshot = try takeProfileSnapshot()
		try keychainClient.saveProfileSnapshot(profileSnapshot: profileSnapshot)
	}

	func asyncMutating<T>(_ mutateProfile: (inout Profile) async throws -> T) async throws -> T {
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
