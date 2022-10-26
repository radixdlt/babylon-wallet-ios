//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-25.
//

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
		engineToolkitClient: EngineToolkitClient = .live,
		maxPollTries: Int = 20,
		pollSleepDuration: TimeInterval = 3
	) -> Self {
		let profileHolder = ProfileHolder.shared

		let makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest: (CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger = { (createAccountRequest: CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in

				print("🎭 Create On-Ledger-Account ✨")
				print("🎭 🛰 🕣 Getting Epoch from GatewayAPI...")
				let epochResponse = try await gatewayAPIClient.getEpoch()
				let epoch = Epoch(rawValue: .init(epochResponse.epoch))
				print("🎭 🛰 🕣 Got Epoch: \(epoch) ✅")

				let buildTransactionRequest = BuildTransactionForCreateOnLedgerAccountRequest(
					privateKey: privateKey,
					epoch: epoch,
					networkID: createAccountRequest.networkID
				)

				print("🎭 🧰 🛠 Building TX with EngineToolkit...")
				let signTXCtx = try engineToolkitClient.buildTransactionForCreateOnLedgerAccount(buildTransactionRequest)
				print("🎭 🧰 🛠 Built TX with EngineToolkit ✅")

				let compileSignedTransactionIntentResponse: CompileSignedTransactionIntentResponse = signTXCtx.compileSignedTransactionIntentResponse
				let compiledSignedIntentBytes = compileSignedTransactionIntentResponse.compiledSignedIntent

				/** A hex-encoded, compiled notarized transaction. */
				let notarizedTransactionHex: String = compiledSignedIntentBytes.hex

				let submitTransactionRequest = V0TransactionSubmitRequest(notarizedTransactionHex: notarizedTransactionHex)
				print("🎭 🛰 💷 Submitting TX to GatewayAPI...")
				let response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
				print("🎭 🛰 💷 Submitted TX to GatewayAPI ☑️")
				guard !response.duplicate else {
					throw FailedToSubmitTransactionWasDuplicate()
				}
				print("🎭 🛰 💷 Submitted TX to GatewayAPI (non duplicate) ✅")

				var txStatus: V0TransactionStatusResponse.IntentStatus = .unknown
				@Sendable func pollTransactionStatus() async throws -> V0TransactionStatusResponse.IntentStatus {
					let txStatusRequest = V0TransactionStatusRequest(intentHash: signTXCtx.transactionIntentHash.hex)
					let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
					return txStatusResponse.intentStatus
				}
				var pollCount = 0
				while !txStatus.isComplete {
					defer { pollCount += 1 }
					try await backgroundQueue.sleep(for: .seconds(pollSleepDuration))
					print("🎭 🛰 🔮 Polling TX status from GatewayAPI...")
					txStatus = try await pollTransactionStatus()
					print("🎭 🛰 🔮 Polled TX status=`\(txStatus.rawValue)` from GatewayAPI ☑️ ")
					if pollCount >= maxPollTries {
						print("🎭 🛰 Failed to get successful TX status after \(pollCount) attempts.")
						throw FailedToGetTransactionStatus()
					}
				}
				print("🎭 🛰 🔮 Polled TX status from GatewayAPI ☑️")
				guard txStatus == .committedSuccess else {
					throw TXWasSubmittedButNotSuccessfully()
				}
				print("🎭 🔮 TX was committed successfully ✅")

//				let intentHash = SHA256.twice(data: Data(compiledSignedIntentBytes))
				let getCommittedTXRequest = V0CommittedTransactionRequest(intentHash: signTXCtx.notarizedTransactionHash.hex)

				print("🎭 🛰 🔮 Getting commited TX from GatewayAPI...")
				let committedResponse = try await gatewayAPIClient.getCommittedTransaction(getCommittedTXRequest)
				print("🎭 🛰 🔮 Got commited TX from GatewayAPI ☑️")
				let committed = committedResponse.committed

				guard committed.receipt.status == .succeeded else {
					throw FailedToSubmitTransactionWasRejected()
				}
				print("🎭 🛰 🔮 Commited TX from GatewayAPI was succeeded ✅")

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
			}
		)
	}
}

// MARK: - FailedToSubmitTransactionWasDuplicate
struct FailedToSubmitTransactionWasDuplicate: Swift.Error {}

// MARK: - FailedToSubmitTransactionWasRejected
struct FailedToSubmitTransactionWasRejected: Swift.Error {}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

// MARK: - FailedToGetTransactionStatus
struct FailedToGetTransactionStatus: Swift.Error {}

// MARK: - TXWasSubmittedButNotSuccessfully
struct TXWasSubmittedButNotSuccessfully: Swift.Error {}

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

public extension V0TransactionStatusResponse.IntentStatus {
	var isComplete: Bool {
		switch self {
		case .committedSuccess, .committedFailure, .rejected: return true
		case .unknown, .inMempool: return false
		}
	}
}
