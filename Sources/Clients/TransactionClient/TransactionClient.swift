import Collections
import Common
import Dependencies
import EngineToolkit
import EngineToolkitClient
import Foundation
@preconcurrency import struct GatewayAPI.GatewayAPIClient
@preconcurrency import struct GatewayAPI.PollStrategy
@preconcurrency import struct GatewayAPI.TransactionDetailsResponse
import NonEmpty
import Profile
import ProfileClient
import SLIP10

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest
	public var defineFunctionToMakeEntityNonVirtualBySubmittingItToLedger: DefineFunctionToMakeEntityNonVirtualBySubmittingItToLedger
	public var signAndSubmitTransaction: SignAndSubmitTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
public extension TransactionClient {
	typealias AddLockFeeInstructionToManifest = @Sendable (TransactionManifest) async throws -> TransactionManifest
	typealias SignAndSubmitTransaction = @Sendable (TransactionManifest) async throws -> Transaction

	typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
}

// MARK: TransactionClient.Transaction
public extension TransactionClient {
	struct Transaction: Sendable, Hashable {
		public let txDetails: GatewayAPI.TransactionDetailsResponse
		public let txID: TXID
	}
}

#if DEBUG
public extension TransactionClient.Transaction {
	static let placeholder: Self = .init(txDetails: .init(ledgerState: .init(network: "placeholder", stateVersion: 1, timestamp: "time", epoch: 1, round: 1), transaction: .init(transactionStatus: .init(status: .succeeded), payloadHashHex: "placeholder", intentHashHex: "placeholder"), details: .init(rawHex: "placeholder", referencedGlobalEntities: [])), txID: "placeholder")
}
#endif // DEBUG

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

public extension TransactionClient {
	static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let pollStrategy: PollStrategy = .default

		@Sendable
		func signAndSubmit(transactionIntent: TransactionIntent, notary notaryPrivateKey: PrivateKey) async throws -> Transaction {
			let compiled = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			let txID = try engineToolkitClient.generateTXID(transactionIntent)

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: []
			)
			let compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)

			let (notarySignature, _) = try notaryPrivateKey.signReturningHashOfMessage(data: compiledSignedIntent.compiledSignedIntent)

			let uncompiledNotarized = try NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature.intoEngine().signature
			)

			let compilededNotarizedTransaction = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)

			let (details, _txID) = try await gatewayAPIClient.submit(
				notarizedTransaction: Data(compilededNotarizedTransaction.compiledNotarizedIntent),
				txID: txID,
				pollStrategy: pollStrategy
			)
			assert(_txID == txID)
			return Transaction(txDetails: details, txID: txID)
		}

		@Sendable
		func signAndSubmit(
			manifest: TransactionManifest,
			getNotary: @escaping (AccountAddressesNeedingToSignTransactionRequest) async throws -> PrivateKey
		) async throws -> Transaction {
			let networkID = await profileClient.getCurrentNetworkID()
			return try await signAndSubmit(
				networkID: networkID,
				manifest: manifest,
				getNotary: getNotary
			)
		}

		@Sendable
		func signAndSubmit(
			networkID: NetworkID,
			manifest: TransactionManifest,
			getNotary: (AccountAddressesNeedingToSignTransactionRequest) async throws -> PrivateKey
		) async throws -> Transaction {
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch = try await gatewayAPIClient.getEpoch()
			let version = engineToolkitClient.getTransactionVersion()

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesNeedingToSignTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			let notaryPrivateKey = try await getNotary(accountAddressesNeedingToSignTransactionRequest)

			let header = TransactionHeader(
				version: version,
				networkId: networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + 5,
				nonce: nonce,
				publicKey: try notaryPrivateKey.publicKey().intoEngine(),
				notaryAsSignatory: true, // FIXME: - mainnet: pass as arg
				costUnitLimit: 10_000_000, // FIXME: - mainnet: pass as arg
				tipPercentage: 0 // FIXME: - mainnet: pass as arg
			)

			let intent = TransactionIntent(
				header: header,
				manifest: manifest
			)

			return try await signAndSubmit(transactionIntent: intent, notary: notaryPrivateKey)
		}

		let convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString = { manifest in
			let version = engineToolkitClient.getTransactionVersion()
			let networkID = await profileClient.getCurrentNetworkID()

			let conversionRequest = ConvertManifestInstructionsToJSONIfItWasStringRequest(
				version: version,
				networkID: networkID,
				manifest: manifest
			)

			return try engineToolkitClient.convertManifestInstructionsToJSONIfItWasString(conversionRequest)
		}

		return Self(
			convertManifestInstructionsToJSONIfItWasString: convertManifestInstructionsToJSONIfItWasString,
			addLockFeeInstructionToManifest: { maybeStringManifest in
				let manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
				var instructions = manifestWithJSONInstructions.instructions
				let networkID = await profileClient.getCurrentNetworkID()
				let lockFeeCallMethodInstruction = try engineToolkitClient.lockFeeCallMethod(faucetForNetwork: networkID).embed()
				instructions.insert(lockFeeCallMethodInstruction, at: 0)
				return TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
			},
			defineFunctionToMakeEntityNonVirtualBySubmittingItToLedger: { networkID -> MakeEntityNonVirtualBySubmittingItToLedger in

				// Define function
				let functionToMakeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in
					print("🎭 Create On-Ledger-Account ✨")

					let manifest = try engineToolkitClient.manifestForOnLedgerAccount(
						networkID: networkID,
						publicKey: privateKey.publicKey()
					)

					let transaction = try await signAndSubmit(manifest: manifest) { _ in privateKey }

					guard
						let addressBech32 = transaction
						.txDetails
						.details
						.referencedGlobalEntities
						.first
					else {
						throw CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities()
					}
					print("🎭 SUCCESSFULLY CREATED ACCOUNT On-Ledger with address: \(addressBech32) ✅ \n txID: \(transaction.txID)")
					return try AccountAddress(address: addressBech32)
				}

				// FIXME: - betanet to be deleted once we have virtual accounts
				return functionToMakeEntityNonVirtualBySubmittingItToLedger
			},
			signAndSubmitTransaction: { manifest in
				try await signAndSubmit(manifest: manifest) { accountAddressesNeedingToSignTransactionRequest in

					// Might be empty
					let addressesNeededToSign = try engineToolkitClient
						.accountAddressesNeedingToSignTransaction(
							accountAddressesNeedingToSignTransactionRequest
						)

					// FIXME: - mainnet: pass as arg a fn: (NonEmpty<>)
					let selectNotary: @Sendable (NonEmpty<OrderedSet<PrivateKey>>) -> PrivateKey = {
						$0.first
					}

					let privateKeys = try await profileClient.privateKeysForAddresses(.init(addresses: .init(addressesNeededToSign), networkID: accountAddressesNeedingToSignTransactionRequest.networkID))

					let notaryPrivateKey = selectNotary(privateKeys)

					return notaryPrivateKey
				}
			}
		)
	}
}

#if DEBUG

import XCTestDynamicOverlay
extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		addLockFeeInstructionToManifest: unimplemented("\(Self.self).addLockFeeInstructionToManifest"),

		defineFunctionToMakeEntityNonVirtualBySubmittingItToLedger:
		unimplemented(
			"\(Self.self).defineFunctionToMakeEntityNonVirtualBySubmittingItToLedger",
			placeholder: unimplemented("\(Self.self).MakeEntityNonVirtualBySubmittingItToLedger")
		),

		signAndSubmitTransaction: unimplemented("\(Self.self).signAndSubmitTransaction")
	)
}
#endif // DEBUG

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}
