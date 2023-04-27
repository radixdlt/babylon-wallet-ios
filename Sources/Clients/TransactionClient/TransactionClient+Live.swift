import AccountPortfoliosClient
import AccountsClient
import CacheClient
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
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient
		@Dependency(\.cacheClient) var cacheClient

		@Sendable
		func accountsWithEnoughFunds(
			from addresses: [AccountAddress],
			toPay fee: BigDecimal
		) async -> Set<AccountPortfolio> {
			guard !addresses.isEmpty else { return Set() }
			guard let portfolios = try? await accountPortfoliosClient.fetchAccountPortfolios(addresses, true) else {
				return Set()
			}
			return Set(portfolios.filter {
				guard let xrdBalance = $0.fungibleResources.xrdResource?.amount else { return false }
				return xrdBalance >= fee
			})
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

		let lockFeeWithSelectedPayer: LockFeeWithSelectedPayer = { maybeStringManifest, feeToAdd, addressOfPayer in
			// assert account still has enough funds to pay
			guard await accountsWithEnoughFunds(from: [addressOfPayer], toPay: feeToAdd).first?.owner == addressOfPayer else {
				assertionFailure("did you JUST spend funds? unlucky...")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
			}

			let manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
			var instructions = manifestWithJSONInstructions.instructions

			loggerGlobal.debug("Setting fee payer to: \(addressOfPayer.address)")
			let lockFeeCallMethodInstruction = engineToolkitClient.lockFeeCallMethod(
				address: ComponentAddress(address: addressOfPayer.address),
				fee: feeToAdd.description
			).embed()

			instructions.insert(lockFeeCallMethodInstruction, at: 0)
			return TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
		}

		let lockFeeBySearchingForSuitablePayer: LockFeeBySearchingForSuitablePayer = { maybeStringManifest, feeToAdd in

			let networkID = await gatewaysClient.getCurrentNetworkID()

			let version = engineToolkitClient.getTransactionVersion()

			let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
			let allCandidates = await accountsWithEnoughFunds(
				from: allAccounts.map(\.address),
				toPay: feeToAdd
			).compactMap { tokenBalance -> FeePayerCandiate? in
				guard
					let account = allAccounts.first(where: { account in account.address == tokenBalance.owner }),
					let xrdBalance = tokenBalance.fungibleResources.xrdResource?.amount
				else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}
				return FeePayerCandiate(
					account: account,
					xrdBalance: xrdBalance
				)
			}

			guard let allCandidatesNonEmpty = NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>(
				rawValue: .init(
					uniqueElements: allCandidates,
					id: \.account.address
				)
			) else {
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
			}

			let accountsSuitableToPayForTXFeeRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: maybeStringManifest,
				networkID: networkID
			)

			let accountAddressesSuitableToPayTransactionFeeRef = try engineToolkitClient
				.accountAddressesSuitableToPayTransactionFee(accountsSuitableToPayForTXFeeRequest)

			guard
				let feePayerInvolvedInTransaction = allCandidates.first(
					where: { candidate in
						accountAddressesSuitableToPayTransactionFeeRef.contains(
							where: { involved in
								involved == candidate.account.address
							}
						)
					}
				)
			else {
				return .excludesLockFee(
					maybeStringManifest,
					feePayerCandidates: allCandidatesNonEmpty,
					feeNotYetAdded: feeToAdd
				)
			}

			let manifestWithLockFee = try await lockFeeWithSelectedPayer(
				maybeStringManifest,
				feeToAdd, feePayerInvolvedInTransaction.account.address
			)

			return .includesLockFee(
				manifestWithLockFee,
				feePayer: .init(
					selected: feePayerInvolvedInTransaction,
					candidates: allCandidatesNonEmpty,
					fee: feeToAdd,
					selection: .auto
				)
			)
		}

		let buildTransactionIntent: BuildTransactionIntent = { request in
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch = try await gatewayAPIClient.getEpoch()
			let version = engineToolkitClient.getTransactionVersion()
			let networkID = request.networkID
			let manifest = request.manifest

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			// Should in fact never be empty, since we should already have added the fee payer, so
			// at least she needs to sign!
			guard let addressesNeededToSign = try NonEmpty(rawValue: OrderedSet(
				engineToolkitClient
					.accountAddressesNeedingToSignTransaction(
						accountAddressesNeedingToSignTransactionRequest
					)
			)) else {
				assertionFailure("addressesNeededToSign was empty, but it shoud never be empty, since we should have added the fee payer already.")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToLoadNotaryAndSigners)
			}

			let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>> = try await {
				let accounts = try await addressesNeededToSign.asyncMap {
					try await accountsClient.getAccountByAddress($0)
				}
				guard let accountsNonEmpty = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: accounts)) else {
					assertionFailure("Should never fail to read accounts")
					throw TransactionFailure.failedToPrepareForTXSigning(.failedToLoadNotaryAndSigners)
				}
				return accountsNonEmpty
			}()

			let notary = await request.selectNotary(accountsNeededToSign)

			let notaryAndSigners = NotaryAndSigners(
				notary: notary,
				accountsNeededToSign: accountsNeededToSign
			)

			let notaryPublicKey = try notaryAndSigners.notary.notaryPublicKey.intoEngine()

			var accountsToSignPublicKeys: [Engine.PublicKey] = []
			for account in notaryAndSigners.accountsNeededToSign {
				switch account.securityState {
				case let .unsecured(unsecuredControl):
					let key = try unsecuredControl.genesisFactorInstance.publicKey.intoEngine()
					accountsToSignPublicKeys.append(key)
				}
			}

			let makeTransactionHeaderInput = request.makeTransactionHeaderInput

			let header = TransactionHeader(
				version: version,
				networkId: networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + makeTransactionHeaderInput.epochWindow,
				nonce: nonce,
				publicKey: notaryPublicKey,
				notaryAsSignatory: notaryAndSigners.notary.notaryAsSignatory,
				costUnitLimit: makeTransactionHeaderInput.costUnitLimit,
				tipPercentage: makeTransactionHeaderInput.tipPercentage
			)

			let intent = TransactionIntent(
				header: header,
				manifest: manifest
			)

			return .init(intent: intent, notaryAndSigners: notaryAndSigners, signerPublicKeys: accountsToSignPublicKeys)
		}

		let notarizeTransaction: NotarizeTransaction = { request in

			let intent = try engineToolkitClient.decompileTransactionIntentRequest(DecompileTransactionIntentRequest(compiledIntent: request.compileTransactionIntent.compiledIntent, instructionsOutputKind: .parsed))

			let signedTransactionIntent = SignedTransactionIntent(
				intent: intent,
				intentSignatures: Array(request.intentSignatures)
			)
			let txID = try engineToolkitClient.generateTXID(intent)
			let compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)

			let notarySignature = try request.notary.sign(hashOfMessage: blake2b(data: compiledSignedIntent.compiledIntent))

			let uncompiledNotarized = try NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature.intoEngine().signature
			)
			let compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)

			func debugPrintTX() {
				// RET prints when convertManifest is called, when it is removed, this can be moved down
				// inline inside `print`.
				let txIntentString = intent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
				print("\n\n🔮 DEBUG TRANSACTION START 🔮")
				print("TXID: \(txID.rawValue)")
				print("TransactionIntent: \(txIntentString)")
				print("intentSignatures: \(signedTransactionIntent.intentSignatures.map(\.signature.hex).joined(separator: "\n"))")
				print("NotarySignature: \(notarySignature)")
				print("Compiled Transaction Intent:\n\n\(request.compileTransactionIntent.compiledIntent.hex)\n\n")
				print("Compiled Notarized Intent:\n\n\(compiledNotarizedTXIntent.compiledIntent.hex)\n\n")
				print("🔮 DEBUG TRANSACTION END 🔮\n\n")
			}

			//            debugPrintTX()
			return .init(notarized: compiledNotarizedTXIntent, txID: txID)
		}

		// TODO: Should the request manifest have lockFee?
		let getTransactionPreview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let transactionPreviewRequest = try await createTransactionPreviewRequest(for: request, networkID: networkID)
			let transactionPreviewResponse = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
			guard transactionPreviewResponse.receipt.status == .succeeded else {
				throw TransactionFailure.failedToPrepareTXReview(
					.failedToRetrieveTXReceipt(transactionPreviewResponse.receipt.errorMessage ?? "Unknown reason")
				)
			}
			let receiptBytes = try [UInt8](hex: transactionPreviewResponse.encodedReceipt)
			let generateTransactionReviewRequest = AnalyzeManifestWithPreviewContextRequest(
				networkId: networkID,
				manifest: request.manifestToSign,
				transactionReceipt: receiptBytes
			)
			let analyzedManifestToReview = try engineToolkitClient.generateTransactionReview(generateTransactionReviewRequest)
			//                .asyncMap { (analyzedManifestToReview: AnalyzeManifestWithPreviewContextResponse) in
			let addFeeToManifestOutcome = try await lockFeeBySearchingForSuitablePayer(request.manifestToSign, request.feeToAdd)
			return TransactionToReview(
				analyzedManifestToReview: analyzedManifestToReview,
				addFeeToManifestOutcome: addFeeToManifestOutcome,
				networkID: networkID
			)
		}

		@Sendable
		func createTransactionPreviewRequest(
			for request: ManifestReviewRequest,
			networkID: NetworkID
		) async throws -> GatewayAPI.TransactionPreviewRequest {
			let intent = try await buildTransactionIntent(.init(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				selectNotary: request.selectNotary
			))

			return GatewayAPI.TransactionPreviewRequest(
				rawManifest: request.manifestToSign,
				header: intent.intent.header,
				signerPublicKeys: intent.signerPublicKeys
			)
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
			lockFeeBySearchingForSuitablePayer: lockFeeBySearchingForSuitablePayer,
			lockFeeWithSelectedPayer: lockFeeWithSelectedPayer,
			addGuaranteesToManifest: addGuaranteesToManifest,
			getTransactionReview: getTransactionPreview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction
		)
	}
}

// MARK: - NotaryAndSigners
public struct NotaryAndSigners: Sendable, Hashable {
	/// Notary signer
	public let notary: NotarySelection
	/// Never empty, since this also contains the notary signer.
	public let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>>

	public init(notary: NotarySelection, accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>>) {
		self.notary = notary
		self.accountsNeededToSign = accountsNeededToSign
	}
}

extension GatewayAPI.TransactionPreviewRequest {
	init(
		rawManifest: TransactionManifest,
		header: TransactionHeader,
		signerPublicKeys: [Engine.PublicKey]
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
			blobsHex: rawManifest.blobs.map(\.hex),
			startEpochInclusive: .init(header.startEpochInclusive.rawValue),
			endEpochExclusive: .init(header.endEpochExclusive.rawValue),
			notaryPublicKey: GatewayAPI.PublicKey(from: header.publicKey),
			notaryAsSignatory: false,
			costUnitLimit: .init(header.costUnitLimit),
			tipPercentage: .init(header.tipPercentage),
			nonce: .init(header.nonce.rawValue),
			signerPublicKeys: signerPublicKeys.map { GatewayAPI.PublicKey(from: $0) },
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
