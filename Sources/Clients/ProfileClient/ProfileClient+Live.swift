import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import GatewayAPI
import KeychainClient
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

public extension ProfileClient {
	static let liveValue: Self = {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let pollStrategy: PollStrategy = .default

		let profileHolder = ProfileHolder.shared

		let getCurrentNetworkID: GetCurrentNetworkID = {
			userDefaultsClient.networkID
		}

		let makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest: (CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger = { (_: CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in

				print("🎭 Create On-Ledger-Account ✨")

				let committed = try await gatewayAPIClient.submit(
					pollStrategy: pollStrategy
				) { epoch in

					let buildAndSignTXRequest = BuildAndSignTransactionRequest(
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

				print("🎭 SUCCESSFULLY CREATED ACCOUNT On-Ledger with address: \(accountAddressBech32) ✅")

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
			injectProfile: {
				profileHolder.injectProfile($0)
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
			getAppPreferences: {
				try profileHolder.get { profile in
					profile.appPreferences
				}
			},
			setDisplayAppPreferences: { newDisplayPreferences in
				try profileHolder.mutating { profile in
					profile.appPreferences.display = newDisplayPreferences
				}
			},
			createAccount: { createAccountRequest in

				try await profileHolder.asyncMutating { profile in

					try await profile.createNewOnLedgerAccount(
						displayName: createAccountRequest.accountName,
						makeEntityNonVirtualBySubmittingItToLedger: makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest(createAccountRequest),
						mnemonicForFactorSourceByReference: { reference in
							try createAccountRequest.keychainClient.loadFactorSourceMnemonic(reference: reference)
						}
					)
				}
			}
		)
	}()
}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

// MARK: - ProfileHolder
private final class ProfileHolder {
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

	func mutating(_ mutateProfile: (inout Profile) throws -> Void) throws {
		guard var profile else {
			throw NoProfile()
		}
		try mutateProfile(&profile)
		self.profile = profile
	}

	func asyncMutating<T>(_ mutateProfile: (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await mutateProfile(&profile)
		self.profile = profile
		return result
	}

	func injectProfile(_ profile: Profile) {
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
