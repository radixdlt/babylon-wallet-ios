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

public extension ProfileClient {
	static func live(
		backgroundQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue(label: "GatewayUsage").eraseToAnyScheduler(),
		gatewayAPIClient: GatewayAPIClient = .live(),
		engineToolkitClient: EngineToolkitClient = .live,
		maxPollTries: Int = 20,
		pollSleepDuration: TimeInterval = 2
	) -> Self {
		let profileHolder = ProfileHolder.shared

		let makeEntityNonVirtualBySubmittingItToLedgerFromCreateAccountRequest: (CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger = { (createAccountRequest: CreateAccountRequest) async throws -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in
				let epochResponse = try await gatewayAPIClient.getEpoch()
				let epoch = Epoch(rawValue: .init(epochResponse.epoch))

				let buildTransactionRequest = BuildTransactionForCreateOnLedgerAccountRequest(
					privateKey: privateKey,
					epoch: epoch,
					networkID: createAccountRequest.networkID
				)
				let compileSignedTransactionIntentResponse: CompileSignedTransactionIntentResponse = try engineToolkitClient.buildTransactionForCreateOnLedgerAccount(buildTransactionRequest)
				let compiledSignedIntentBytes = compileSignedTransactionIntentResponse.compiledSignedIntent

				/** A hex-encoded, compiled notarized transaction. */
				let notarizedTransactionHex: String = compiledSignedIntentBytes.hex

				let submitTransactionRequest = V0TransactionSubmitRequest(notarizedTransactionHex: notarizedTransactionHex)
				let response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
				guard response.duplicate else {
					throw FailedToSubmitTransactionWasDuplicate()
				}

				var txStatus: V0TransactionStatusResponse.IntentStatus = .unknown
				@Sendable func pollTransactionStatus() async throws -> V0TransactionStatusResponse.IntentStatus {
					.committedFailure
				}
				var pollCount = 0
				while txStatus != .committedSuccess || txStatus != .committedFailure || txStatus != .rejected {
					defer { pollCount += 1 }
					try await backgroundQueue.sleep(for: .seconds(pollSleepDuration))
					txStatus = try await pollTransactionStatus()
					if pollCount >= maxPollTries {
						throw FailedToGetTransactionStatus()
					}
				}
				let intentHash = SHA256.hashTwice(data: Data(compiledSignedIntentBytes))
				let getCommittedTXRequest = V0CommittedTransactionRequest(intentHash: intentHash.hex)
				let committedResponse = try await gatewayAPIClient.getCommittedTransaction(getCommittedTXRequest)
				let committed = committedResponse.committed

				guard committed.receipt.status == .succeeded else {
					throw FailedToSubmitTransactionWasRejected()
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
