import AccountPortfolioFetcherClient
import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import FactorSourcesClient
import GatewayAPI
import GatewaysClient
import Resources
import SecureStorageClient
import UseFactorSourceClient

extension TransactionClient {
	public static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.accountPortfolioFetcherClient) var accountPortfolioFetcherClient
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient

		let pollStrategy: PollStrategy = .default

		@Sendable
		func compileAndSign(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> Result<(txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse), TransactionFailure.CompileOrSignFailure> {
			let compiledTransactionIntent: CompileTransactionIntentResponse
			do {
				compiledTransactionIntent = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			} catch {
				return .failure(.failedToCompileTXIntent)
			}

			let txID: TXID
			do {
				txID = try engineToolkitClient.generateTXID(transactionIntent)
			} catch {
				return .failure(.failedToGenerateTXId)
			}

			// Enables us to only read from keychain once per mnemonic
			let cachedPrivateHDFactorSources = ActorIsolated<IdentifiedArrayOf<PrivateHDFactorSource>>([])

			@Sendable func sign(
				unhashed unhashed_: some DataProtocol,
				with account: Profile.Network.Account,
				debugOrigin origin: String
			) async throws -> SignatureWithPublicKey {
				switch account.securityState {
				case let .unsecured(unsecuredControl):
					let factorInstance = unsecuredControl.genesisFactorInstance
					let factorSources = try await factorSourcesClient.getFactorSources()

					let privateHDFactorSource: PrivateHDFactorSource = try await { @Sendable () async throws -> PrivateHDFactorSource in

						let cache = await cachedPrivateHDFactorSources.value
						if let cached = cache[id: factorInstance.factorSourceID] {
							return cached
						}

						guard
							let factorSource = factorSources[id: factorInstance.factorSourceID],
							let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorInstance.factorSourceID, .signTransaction)
						else {
							throw TransactionFailure.failedToCompileOrSign(.failedToLoadFactorSourceForSigning)
						}

						let privateHDFactorSource = try PrivateHDFactorSource(
							mnemonicWithPassphrase: loadedMnemonicWithPassphrase,
							hdOnDeviceFactorSource: .init(factorSource: factorSource)
						)

						await cachedPrivateHDFactorSources.setValue(cache.appending(privateHDFactorSource))

						return privateHDFactorSource
					}()

					let hdRoot = try privateHDFactorSource.mnemonicWithPassphrase.hdRoot()
					let curve = privateHDFactorSource.hdOnDeviceFactorSource.parameters.supportedCurves.last
					let unhashedData = Data(unhashed_)

					loggerGlobal.debug("🔏 Signing data, origin=\(origin), with account=\(account.displayName), curve=\(curve), factorSourceKind=\(privateHDFactorSource.hdOnDeviceFactorSource.kind), factorSourceHint=\(privateHDFactorSource.hdOnDeviceFactorSource.hint)")

					return try await useFactorSourceClient.signatureFromOnDeviceHD(.init(
						hdRoot: hdRoot,
						derivationPath: factorInstance.derivationPath!,
						curve: curve,
						unhashedData: unhashedData
					))
				}
			}

			let intentSignatures_: [SignatureWithPublicKey]
			do {
				intentSignatures_ = try await notaryAndSigners.accountsNeededToSign.asyncMap {
					try await sign(
						unhashed: compiledTransactionIntent.compiledIntent,
						with: $0,
						debugOrigin: "Intent Signers"
					)
				}
			} catch {
				return .failure(.failedToSignIntentWithAccountSigners)
			}

			let intentSignatures: [Engine.SignatureWithPublicKey]
			do {
				intentSignatures = try intentSignatures_.map { try $0.intoEngine() }
			} catch {
				return .failure(.failedToConvertAccountSignatures)
			}

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: intentSignatures
			)
			let compiledSignedIntent: CompileSignedTransactionIntentResponse
			do {
				compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)
			} catch {
				return .failure(.failedToCompileSignedTXIntent)
			}

			let notarySignatureWithPublicKey: SignatureWithPublicKey
			do {
				notarySignatureWithPublicKey = try await sign(
					unhashed: compiledSignedIntent.compiledIntent,
					with: notaryAndSigners.notarySigner,
					debugOrigin: "Notary signer"
				)
			} catch {
				return .failure(.failedToSignSignedCompiledIntentWithNotarySigner)
			}

			let notarySignature: Engine.Signature
			do {
				notarySignature = try notarySignatureWithPublicKey.intoEngine().signature
			} catch {
				return .failure(.failedToConvertNotarySignature)
			}
			let uncompiledNotarized = NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature
			)
			let compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
			do {
				compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)
			} catch {
				return .failure(.failedToCompileNotarizedTXIntent)
			}

			func debugPrintTX() {
				// RET prints when convertManifest is called, when it is removed, this can be moved down
				// inline inside `print`.
				let txIntentString = transactionIntent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
				print("\n\n🔮 DEBUG TRANSACTION START 🔮")
				print("TXID: \(txID.rawValue)")
				print("TransactionIntent: \(txIntentString)")
				print("intentSignatures: \(signedTransactionIntent.intentSignatures.map(\.signature.hex).joined(separator: "\n"))")
				do {
					try print("NotarySignature: \(notarySignatureWithPublicKey.signature.serialize().hex)")
				} catch {}
				print("Compiled Transaction Intent:\n\n\(compiledTransactionIntent.compiledIntent.hex)\n\n")
				print("Compiled Notarized Intent:\n\n\(compiledNotarizedTXIntent.compiledIntent.hex)\n\n")
				print("🔮 DEBUG TRANSACTION END 🔮\n\n")
			}

//			debugPrintTX()

			return .success((txID: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent))
		}

		@Sendable
		func submitNotarizedTX(
			id txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
		) async -> Result<TXID, SubmitTXFailure> {
			@Dependency(\.continuousClock) var clock

			// MARK: Submit TX

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: Data(compiledNotarizedTXIntent.compiledIntent).hex
			)

			let response: GatewayAPI.TransactionSubmitResponse

			do {
				response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
			} catch {
				return .failure(.failedToSubmitTX)
			}

			guard !response.duplicate else {
				return .failure(.invalidTXWasDuplicate(txID: txID))
			}

			// MARK: Poll Status

			var txStatus: GatewayAPI.TransactionStatus = .pending

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHashHex: txID.rawValue
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse.status
			}

			var pollCount = 0
			while !txStatus.isComplete {
				defer { pollCount += 1 }
				try? await clock.sleep(for: .seconds(pollStrategy.sleepDuration))

				do {
					txStatus = try await pollTransactionStatus()
				} catch {
					// FIXME: - mainnet: improve handling of polling failure, should probably not return failure..
					return .failure(.failedToPollTX(txID: txID, error: .init(error: error)))
				}

				if pollCount >= pollStrategy.maxPollTries {
					return .failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollCount)))
				}
			}
			guard txStatus == .committedSuccess else {
				return .failure(.invalidTXWasSubmittedButNotSuccessful(txID: txID, status: txStatus == .rejected ? .rejected : .failed))
			}

			return .success(txID)
		}

		@Sendable
		func signAndSubmit(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> TransactionResult {
			await compileAndSign(transactionIntent: transactionIntent, notaryAndSigners: notaryAndSigners)
				.mapError { TransactionFailure.failedToCompileOrSign($0) }
				.asyncFlatMap { (txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse) in
					await submitNotarizedTX(id: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent).mapError {
						TransactionFailure.failedToSubmit($0)
					}
				}
		}

		let convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString = { manifest in
			let version = engineToolkitClient.getTransactionVersion()
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let conversionRequest = ConvertManifestInstructionsToJSONIfItWasStringRequest(
				version: version,
				networkID: networkID,
				manifest: manifest
			)

			return try engineToolkitClient.convertManifestInstructionsToJSONIfItWasString(conversionRequest)
		}

		let addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest = { maybeStringManifest in
			let manifestWithJSONInstructions: JSONInstructionsTransactionManifest
			do {
				manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
			} catch {
				loggerGlobal.error("Failed to convert manifest: \(String(describing: error))")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid)
			}

			var instructions = manifestWithJSONInstructions.instructions
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let version = engineToolkitClient.getTransactionVersion()

			let accountsSuitableToPayForTXFeeRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifestWithJSONInstructions.convertedManifestThatContainsThem,
				networkID: networkID
			)

			let feeAdded: BigDecimal = 10

			let accountAddress: AccountAddress = try await { () async throws -> AccountAddress in
				let accountAddressesSuitableToPayTransactionFeeRef =
					try engineToolkitClient.accountAddressesSuitableToPayTransactionFee(accountsSuitableToPayForTXFeeRequest)

				if let accountInvolvedInTransaction = await firstAccountAddressWithEnoughFunds(
					from: Array(accountAddressesSuitableToPayTransactionFeeRef),
					toPay: feeAdded,
					on: networkID
				) {
					return accountInvolvedInTransaction
				} else {
					let allAccountAddresses = try await accountsClient.getAccountsOnCurrentNetwork().map(\.address)

					if let anyAccount = await firstAccountAddressWithEnoughFunds(
						from: allAccountAddresses.rawValue,
						toPay: feeAdded,
						on: networkID
					) {
						return anyAccount
					} else {
						throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
					}
				}
			}()

			let lockFeeCallMethodInstruction = engineToolkitClient.lockFeeCallMethod(
				address: ComponentAddress(address: accountAddress.address),
				fee: feeAdded.description
			).embed()

			instructions.insert(lockFeeCallMethodInstruction, at: 0)
			let manifest = TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
			return (manifest, feeAdded)
		}

		// TODO: Should the request manifest have lockFee?
		let getTransactionPreview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let transactionPreviewRequest = try await createTransactionPreviewRequest(
				for: request,
				networkID: networkID
			).get()

			let response = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
			let receiptBytes = try [UInt8](hex: response.encodedReceipt)

			let generateTransactionReviewRequest = AnalyzeManifestWithPreviewContextRequest(
				networkId: networkID,
				manifest: request.manifestToSign,
				transactionReceipt: receiptBytes
			)

			let analyzedManifestToReview = try engineToolkitClient.generateTransactionReview(generateTransactionReviewRequest)

			let (manifestIncludingLockFee, transactionFeeAdded) = try await addLockFeeInstructionToManifest(request.manifestToSign)

			return TransactionToReview(
				analyzedManifestToReview: analyzedManifestToReview,
				manifestIncludingLockFee: manifestIncludingLockFee,
				transactionFeeAdded: transactionFeeAdded
			)
		}

		@Sendable
		func buildTransactionIntent(
			networkID: NetworkID,
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> Result<(intent: TransactionIntent, notaryAndSigners: NotaryAndSigners), TransactionFailure.FailedToPrepareForTXSigning> {
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch: Epoch
			do {
				epoch = try await gatewayAPIClient.getEpoch()
			} catch {
				return .failure(.failedToGetEpoch)
			}

			let version = engineToolkitClient.getTransactionVersion()

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			let notaryAndSigners: NotaryAndSigners
			do {
				notaryAndSigners = try await getNotaryAndSigners(accountAddressesNeedingToSignTransactionRequest)
			} catch {
				return .failure(.failedToLoadNotaryAndSigners)
			}
			let notaryPublicKey: Engine.PublicKey
			do {
				let notarySigner = notaryAndSigners.notarySigner
				switch notarySigner.securityState {
				case let .unsecured(unsecuredControl):
					notaryPublicKey = try unsecuredControl.genesisFactorInstance.publicKey.intoEngine()
				}
			} catch {
				return .failure(.failedToLoadNotaryPublicKey)
			}

			let header = TransactionHeader(
				version: version,
				networkId: networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + makeTransactionHeaderInput.epochWindow,
				nonce: nonce,
				publicKey: notaryPublicKey,
				notaryAsSignatory: false,
				costUnitLimit: makeTransactionHeaderInput.costUnitLimit,
				tipPercentage: makeTransactionHeaderInput.tipPercentage
			)

			let intent = TransactionIntent(
				header: header,
				manifest: manifest
			)

			return .success((intent, notaryAndSigners))
		}

		@Sendable
		func getNotaryAndSigners(
			_ accountAddressesNeedingToSignTransactionRequest: AccountAddressesInvolvedInTransactionRequest,
			selectNotary: SelectNotary
		) async throws -> NotaryAndSigners {
			// Might be empty
			let addressesNeededToSign = try OrderedSet(
				engineToolkitClient
					.accountAddressesNeedingToSignTransaction(
						accountAddressesNeedingToSignTransactionRequest
					)
			)

			let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>> = try await {
				let accounts = try await addressesNeededToSign.asyncMap {
					try await accountsClient.getAccountByAddress($0)
				}
				guard let accounts = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: accounts)) else {
					// TransactionManifest does not reference any accounts => use any account!
					let first = try await accountsClient.getAccountsOnNetwork(accountAddressesNeedingToSignTransactionRequest.networkID).first
					return NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: [first]))!
				}
				return accounts
			}()

			let notary = await selectNotary(accountsNeededToSign)

			return .init(notarySigner: notary, accountsNeededToSign: accountsNeededToSign)
		}

		@Sendable
		func createTransactionPreviewRequest(
			for request: ManifestReviewRequest,
			networkID: NetworkID
		) async -> Result<GatewayAPI.TransactionPreviewRequest, TransactionFailure.FailedToPrepareForTXSigning> {
			await buildTransactionIntent(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				getNotaryAndSigners: {
					try await getNotaryAndSigners($0, selectNotary: request.selectNotary)
				}
			).map {
				GatewayAPI.TransactionPreviewRequest(
					rawManifest: request.manifestToSign,
					header: $0.intent.header
				)
			}
		}

		@Sendable
		func signAndSubmit(
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @escaping @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> TransactionResult {
			await buildTransactionIntent(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: manifest,
				makeTransactionHeaderInput: makeTransactionHeaderInput,
				getNotaryAndSigners: getNotaryAndSigners
			).mapError {
				TransactionFailure.failedToPrepareForTXSigning($0)
			}.asyncFlatMap { intent, notaryAndSigners in
				await signAndSubmit(transactionIntent: intent, notaryAndSigners: notaryAndSigners)
			}
		}

		let signAndSubmitTransaction: SignAndSubmitTransaction = { @Sendable request in
			await signAndSubmit(
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput
			) { accountAddressesNeedingToSignTransactionRequest in

				// Might be empty
				let addressesNeededToSign = try OrderedSet(
					engineToolkitClient
						.accountAddressesNeedingToSignTransaction(
							accountAddressesNeedingToSignTransactionRequest
						)
				)

				let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>> = try await {
					let accounts = try await addressesNeededToSign.asyncMap {
						try await accountsClient.getAccountByAddress($0)
					}
					guard let accounts = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: accounts)) else {
						// TransactionManifest does not reference any accounts => use any account!
						let first = try await accountsClient.getAccountsOnNetwork(accountAddressesNeedingToSignTransactionRequest.networkID).first
						return NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: [first]))!
					}
					return accounts
				}()

				let notary = await request.selectNotary(accountsNeededToSign)

				return .init(notarySigner: notary, accountsNeededToSign: accountsNeededToSign)
			}
		}

		@Sendable
		func firstAccountAddressWithEnoughFunds(from addresses: [AccountAddress], toPay fee: BigDecimal, on networkID: NetworkID) async -> AccountAddress? {
			let xrdContainers = await addresses.concurrentMap {
				await accountPortfolioFetcherClient.fetchXRDBalance(of: $0, on: networkID)
			}.compactMap { $0 }
			return xrdContainers.first(where: { $0.amount >= fee })?.owner
		}

		@Sendable
		func addGuaranteesToManifest(_ manifestWithLockFee: TransactionManifest, guarantees: [Guarantee]) async throws -> TransactionManifest {
			let manifestWithJSONInstructions: JSONInstructionsTransactionManifest
			do {
				manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(manifestWithLockFee)
			} catch {
				loggerGlobal.error("Failed to convert manifest: \(String(describing: error))")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid)
			}

			var instructions = manifestWithJSONInstructions.instructions
			/// Will be increased with each added guarantee to account for the difference in indexes from the initial manifest.
			var indexInc = 1 // LockFee was added, start from 1
			for guarantee in guarantees {
				let guaranteeInstruction: Instruction = .assertWorktopContainsByAmount(.init(amount: .init(value: guarantee.amount.toString()), resourceAddress: guarantee.resourceAddress))
				instructions.insert(guaranteeInstruction, at: Int(guarantee.instructionIndex) + indexInc)
				indexInc += 1
			}
			return TransactionManifest(instructions: instructions, blobs: manifestWithLockFee.blobs)
		}

		return Self(
			convertManifestInstructionsToJSONIfItWasString: convertManifestInstructionsToJSONIfItWasString,
			addLockFeeInstructionToManifest: addLockFeeInstructionToManifest,
			addGuaranteesToManifest: addGuaranteesToManifest,
			signAndSubmitTransaction: signAndSubmitTransaction,
			getTransactionReview: getTransactionPreview
		)
	}
}

// MARK: - NotaryAndSigners
struct NotaryAndSigners: Sendable, Hashable {
	/// Notary signer
	public let notarySigner: Profile.Network.Account
	/// Never empty, since this also contains the notary signer.
	public let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>>
}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch self {
		case .committedSuccess, .committedFailure, .rejected:
			return true
		case .pending, .unknown:
			return false
		}
	}
}

// MARK: - PollStrategy
public struct PollStrategy {
	public let maxPollTries: Int
	public let sleepDuration: TimeInterval
	public init(maxPollTries: Int, sleepDuration: TimeInterval) {
		self.maxPollTries = maxPollTries
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(maxPollTries: 20, sleepDuration: 2)
}

// MARK: - GatewayAPI.TransactionCommittedDetailsResponse + Sendable
extension GatewayAPI.TransactionCommittedDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.TransactionStatus + Sendable
extension GatewayAPI.TransactionStatus: @unchecked Sendable {}

// MARK: - FailedToGetDetailsOfSuccessfullySubmittedTX
struct FailedToGetDetailsOfSuccessfullySubmittedTX: LocalizedError, Equatable {
	public let txID: TXID
	var errorDescription: String? {
		"Successfully submitted TX with txID: \(txID) but failed to get transaction details for it."
	}
}

// MARK: - SubmitTXFailure
// FIXME: - mainnet: improve handling of polling failure
/// This failure might be a false positive, due to i.e. POLLING of tx failed, but TX might have
/// been submitted successfully. Or we might have successfully submitted the TX but failed to get details about it.
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate(txID: TXID)

	/// Failed to poll, maybe TX was submitted successfully?
	case failedToPollTX(txID: TXID, error: FailedToPollError)

	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: TXFailureStatus)

	public var errorDescription: String? {
		switch self {
		case .failedToSubmitTX:
			return "Failed to submit transaction"
		case let .invalidTXWasDuplicate(txID):
			return "Duplicate TX id: \(txID)"
		case let .failedToPollTX(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .failedToGetTransactionStatus(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .invalidTXWasSubmittedButNotSuccessful(txID, status):
			return "Invalid TX submitted but not successful, status: \(status.localizedDescription) txID: \(txID)"
		}
	}
}

// MARK: - TXFailureStatus
public enum TXFailureStatus: String, LocalizedError, Sendable, Hashable {
	case rejected
	case failed
	public var errorDescription: String? {
		switch self {
		case .rejected: return "Rejected"
		case .failed: return "Failed"
		}
	}
}

// MARK: - FailedToPollError
public struct FailedToPollError: Sendable, LocalizedError, Equatable {
	public let error: Swift.Error
	public var errorDescription: String? {
		"Poll failed: \(String(describing: error))"
	}
}

// MARK: - FailedToGetTransactionStatus
public struct FailedToGetTransactionStatus: Sendable, LocalizedError, Equatable {
	public let pollAttempts: Int
	public var errorDescription: String? {
		"\(Self.self)(afterPollAttempts: \(String(describing: pollAttempts))"
	}
}

extension LocalizedError where Self: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}

extension IdentifiedArrayOf {
	func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
	}
}

extension GatewayAPI.TransactionPreviewRequest {
	init(
		rawManifest: TransactionManifest,
		header: TransactionHeader
	) {
		let manifestString = {
			switch rawManifest.instructions {
			case let .string(manifestString): return manifestString
			case .parsed: fatalError("you should have converted manifest to string first")
			}
		}()

		let flags = GatewayAPI.TransactionPreviewRequestFlags(
			unlimitedLoan: true, // True since no lock fee is added
			assumeAllSignatureProofs: false,
			permitDuplicateIntentHash: false,
			permitInvalidHeaderEpoch: false
		)

		self.init(
			manifest: manifestString,
			blobsHex: [],
			startEpochInclusive: .init(header.startEpochInclusive.rawValue),
			endEpochExclusive: .init(header.endEpochExclusive.rawValue),
			notaryPublicKey: GatewayAPI.PublicKey(from: header.publicKey),
			notaryAsSignatory: false,
			costUnitLimit: .init(header.costUnitLimit),
			tipPercentage: .init(header.tipPercentage),
			nonce: .init(header.nonce.rawValue),
			signerPublicKeys: [GatewayAPI.PublicKey(from: header.publicKey)],
			flags: flags
		)
	}
}

extension GatewayAPI.PublicKey {
	init(from engine: Engine.PublicKey) {
		switch engine {
		case let .ecdsaSecp256k1(key):
			self = .ecdsaSecp256k1(.init(keyType: .ecdsaSecp256k1, keyHex: key.bytes.hex))
		case let .eddsaEd25519(key):
			self = .eddsaEd25519(.init(keyType: .eddsaEd25519, keyHex: key.bytes.hex))
		}
	}
}
