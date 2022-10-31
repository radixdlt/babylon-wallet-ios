import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import GatewayAPI
import KeychainClient
import Profile
import SLIP10

public extension ProfileClient {
	static func live(
		backgroundQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue(label: "GatewayUsage").eraseToAnyScheduler(),
		gatewayAPIClient: GatewayAPIClient = .live(),
		engineToolkitClient: EngineToolkitClient = .liveValue,
		pollStrategy: PollStrategy = .default
	) -> Self {
		let profileHolder = ProfileHolder.shared

		let makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest: (CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger = { (createAccountRequest: CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in

				print("🎭 Create On-Ledger-Account ✨")

				let committed = try await gatewayAPIClient.submit(
					pollStrategy: pollStrategy,
					backgroundQueue: backgroundQueue
				) { epoch in

					let buildAndSignTXRequest = BuildAndSignTransactionRequest(
						privateKey: privateKey,
						epoch: epoch,
						networkID: createAccountRequest.networkID
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
			createNewProfile: { request in
				try await Profile.new(
					mnemonic: request.curve25519FactorSourceMnemonic,
					firstAccountDisplayName: request.createFirstAccountRequest.accountName,
					makeFirstAccountNonVirtualBySubmittingItToLedger: makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest(request.createFirstAccountRequest)
				)
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
			setDisplayAppPreferences: { _ in
				try profileHolder.setting { _ in
				}
			},
			createAccount: { createAccountRequest in

				try await profileHolder.asyncSetting { profile in

					try await profile.createNewOnLedgerAccount(
						displayName: createAccountRequest.accountName,
						makeEntityNonVirtualBySubmittingItToLedger: makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest(createAccountRequest),
						mnemonicForFactorSourceByReference: { reference in
							try createAccountRequest.keychainClient.loadFactorSourceMnemonic(reference: reference)
						}
					)
				}
			},
			signTransaction: { accountID, transactionManifest in
				// TODO: implement
				return "TXID"
			}
		)
	}
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

	func setting(_ setProfile: (inout Profile) throws -> Void) throws {
		guard var profile else {
			throw NoProfile()
		}
		try setProfile(&profile)
		self.profile = profile
	}

	func asyncSetting<T>(_ setProfile: (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await setProfile(&profile)
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
