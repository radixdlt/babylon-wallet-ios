import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import struct GatewayAPI.GatewayAPIClient
import struct GatewayAPI.PollStrategy
import KeychainClientDependency
import Profile
import SLIP10
import UserDefaultsClient

private let currentNetworkIDKey = "currentNetworkIDKey"
public extension UserDefaultsClient {
	func setNetworkID(_ networkID: NetworkID) async {
		await setInteger(Int(networkID.id), currentNetworkIDKey)
	}

	var networkID: NetworkID {
		guard case let int = integerForKey(currentNetworkIDKey), int > 0 else {
			return .primary
		}
		return NetworkID(.init(int))
	}
}

// MARK: - ProfileClient + DependencyKey
extension ProfileClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.keychainClient) var keychainClient

		let pollStrategy: PollStrategy = .default

		let profileHolder = ProfileHolder.shared

		let getCurrentNetworkID: GetCurrentNetworkID = {
			userDefaultsClient.networkID
		}

		let makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest: (CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger = { (_: CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in

				print("🎭 Create On-Ledger-Account ✨")

				let (committed, txID) = try await gatewayAPIClient.submit(
					pollStrategy: pollStrategy
				) { epoch in

					let buildAndSignTXRequest = BuildAndSignTransactionWithoutManifestRequest(
						privateKey: privateKey,
						epoch: epoch,
						networkID: getCurrentNetworkID()
					)

					return try engineToolkitClient.createAccount(request: buildAndSignTXRequest)
				}

				guard let accountAddressBech32 = committed
					.receipt
					.stateUpdates
					.newGlobalEntities
					.first?
					.globalAddress
				else {
					throw CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities()
				}

				print("🎭 SUCCESSFULLY CREATED ACCOUNT On-Ledger with address: \(accountAddressBech32) ✅ \n txID: \(txID)")

				return try AccountAddress(address: accountAddressBech32)
			}

			return makeEntityNonVirtualBySubmittingItToLedger
		}

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			setCurrentNetworkID: { newNetworkID in
				await userDefaultsClient.setNetworkID(newNetworkID)
			},
			createNewProfile: { request in

				// Get default NetworkID
				let networkID = getCurrentNetworkID()
				// Save NetworkID if needed (needed first time wallet launches)
				await userDefaultsClient.setNetworkID(networkID)

				let newProfile = try await Profile.new(
					networkID: networkID,
					mnemonic: request.curve25519FactorSourceMnemonic,
					firstAccountDisplayName: request.createFirstAccountRequest.accountName,
					makeFirstAccountNonVirtualBySubmittingItToLedger: makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest(request.createFirstAccountRequest)
				)

				return newProfile
			},
			injectProfile: { profile, mode in
				try await profileHolder.injectProfile(profile, mode: mode)
			},
			extractProfileSnapshot: {
				try profileHolder.takeProfileSnapshot()
			},
			deleteProfileSnapshot: {
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
			getAppPreferences: {
				try profileHolder.get { profile in
					profile.appPreferences
				}
			},
			setDisplayAppPreferences: { newDisplayPreferences in
				try await profileHolder.asyncMutating { profile in
					profile.appPreferences.display = newDisplayPreferences
				}
			},
			createAccount: { createAccountRequest in
				try await profileHolder.asyncMutating { profile in

					try await profile.createNewOnLedgerAccount(
						displayName: createAccountRequest.accountName,
						makeEntityNonVirtualBySubmittingItToLedger: makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest(createAccountRequest),
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
			signTransaction: { account, manifest in
				try await profileHolder.getAsync { profile in
					try await profile.withPrivateKeys(
						of: account,
						mnemonicForFactorSourceByReference: { [keychainClient] reference in
							try keychainClient.loadFactorSourceMnemonic(reference: reference)
						}
					) { privateKeys in
						let privateKey = privateKeys.first
						print("🔏 Signing transaction and submitting to Ledger ✨")

						let (_, txID) = try await gatewayAPIClient.submit(
							pollStrategy: pollStrategy
						) { epoch in

							let signReq = BuildAndSignTransactionWithManifestRequest(
								manifest: manifest,
								privateKey: privateKey,
								epoch: epoch,
								networkID: getCurrentNetworkID()
							)

							return try engineToolkitClient.sign(request: signReq)
						}

						print("🔏 SUCCESSFULLY Signing transaction and submitting to Ledger ✅")
						return txID
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

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

// MARK: - ProfileHolder
private final class ProfileHolder {
	@Dependency(\.keychainClient) var keychainClient
	private var profile: Profile?
	private init() {}
	fileprivate static let shared = ProfileHolder()

	struct NoProfile: Swift.Error {}

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

	func injectProfile(_ profile: Profile, mode: InjectProfileMode) async throws {
		self.profile = profile
		switch mode {
		case .injectAndPersistInKeychain:
			try await persistProfile()
		case .onlyInject: break
		}
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
