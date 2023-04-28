import AccountPortfoliosClient
import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import GatewayAPI
import GatewaysClient
import Resources

extension TransactionClient {
	public static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

		@Sendable
		func getTransactionSigners(_ request: BuildTransactionIntentRequest) async throws -> TransactionSigners {
			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: engineToolkitClient.getTransactionVersion(),
				manifest: request.manifest,
				networkID: request.networkID
			)

			let addressesNeededToSign = try OrderedSet(
				engineToolkitClient
					.accountAddressesNeedingToSignTransaction(
						accountAddressesNeedingToSignTransactionRequest
					)
			)

			let accounts = try await OrderedSet(addressesNeededToSign.asyncMap {
				try await accountsClient.getAccountByAddress($0)
			})

			let intentSigning: TransactionSigners.IntentSigning = {
				if let nonEmpty = NonEmpty(rawValue: accounts) {
					return .intentSigners(nonEmpty)
				} else {
					return .notaryAsSignatory
				}
			}()

			return .init(
				notaryPublicKey: request.ephemeralNotaryPublicKey,
				intentSigning: intentSigning
			)
		}

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
			let epoch = try await gatewayAPIClient.getEpoch()
			let transactionSigners = try await getTransactionSigners(request)

			let header = try TransactionHeader(
				version: engineToolkitClient.getTransactionVersion(),
				networkId: request.networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + request.makeTransactionHeaderInput.epochWindow,
				nonce: engineToolkitClient.generateTXNonce(),
				publicKey: SLIP10.PublicKey.eddsaEd25519(transactionSigners.notaryPublicKey).intoEngine(),
				notaryAsSignatory: transactionSigners.notaryAsSignatory,
				costUnitLimit: request.makeTransactionHeaderInput.costUnitLimit,
				tipPercentage: request.makeTransactionHeaderInput.tipPercentage
			)

			let intent = TransactionIntent(
				header: header,
				manifest: request.manifest
			)

			return .init(
				intent: intent,
				transactionSigners: transactionSigners
			)
		}

		let notarizeTransaction: NotarizeTransaction = { request in

			let intent = try engineToolkitClient.decompileTransactionIntentRequest(.init(
				compiledIntent: request.compileTransactionIntent.compiledIntent,
				instructionsOutputKind: .parsed
			))

			let signedTransactionIntent = SignedTransactionIntent(
				intent: intent,
				intentSignatures: Array(request.intentSignatures)
			)
			let txID = try engineToolkitClient.generateTXID(intent)
			let compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)

			let notarySignature = try request.notary.sign(
				hashOfMessage: blake2b(data: compiledSignedIntent.compiledIntent)
			)

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
			let addFeeToManifestOutcome = try await lockFeeBySearchingForSuitablePayer(
				request.manifestToSign,
				request.feeToAdd
			)
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
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			return try .init(
				rawManifest: request.manifestToSign,
				header: intent.intent.header,
				transactionSigners: intent.transactionSigners
			)
		}

		@Sendable
		func addGuaranteesToManifest(
			_ manifestWithLockFee: TransactionManifest,
			guarantees: [Guarantee]
		) async throws -> TransactionManifest {
			let manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(manifestWithLockFee)
			var instructions = manifestWithJSONInstructions.instructions

			/// Will be increased with each added guarantee to account for the difference in indexes from the initial manifest.
			var indexInc = 1 // LockFee was added, start from 1
			for guarantee in guarantees {
				let guaranteeInstruction: Instruction = .assertWorktopContainsByAmount(.init(
					amount: .init(
						value: guarantee.amount.toString()
					),
					resourceAddress: guarantee.resourceAddress
				))
				instructions.insert(
					guaranteeInstruction,
					at: Int(guarantee.instructionIndex) + indexInc
				)
				indexInc += 1
			}
			return TransactionManifest(
				instructions: instructions,
				blobs: manifestWithLockFee.blobs
			)
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
