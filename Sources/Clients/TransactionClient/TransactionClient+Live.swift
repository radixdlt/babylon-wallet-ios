import AccountPortfolioFetcherClient
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
		@Dependency(\.accountPortfolioFetcherClient) var accountPortfolioFetcherClient
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient
		@Dependency(\.cacheClient) var cacheClient

		@Sendable
		func accountsWithEnoughFunds(
			from addresses: [AccountAddress],
			toPay fee: BigDecimal
		) async -> Set<FungibleTokenContainer> {
			guard !addresses.isEmpty else { return Set() }
			let xrdContainers = await addresses.concurrentMap {
				await accountPortfolioFetcherClient.fetchXRDBalance(of: $0, forceRefresh: true)
			}.compactMap { $0 }
			return Set(xrdContainers.filter { $0.amount >= fee })
		}

		@Sendable
		func firstAccountAddressWithEnoughFunds(
			from addresses: [AccountAddress],
			toPay fee: BigDecimal
		) async -> FungibleTokenContainer? {
			await accountsWithEnoughFunds(from: addresses, toPay: fee).first
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
			guard
				let balance = await accountPortfolioFetcherClient.fetchXRDBalance(
					of: addressOfPayer,
					forceRefresh: true
				)?.amount,
				balance >= feeToAdd
			else {
				fatalError()
			}

			let manifestWithJSONInstructions: JSONInstructionsTransactionManifest
			do {
				manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
			} catch {
				loggerGlobal.error("Failed to convert manifest: \(String(describing: error))")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid)
			}
			var instructions = manifestWithJSONInstructions.instructions

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

			let accountsSuitableToPayForTXFeeRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: maybeStringManifest,
				networkID: networkID
			)

			let accountAddressesSuitableToPayTransactionFeeRef = try engineToolkitClient
				.accountAddressesSuitableToPayTransactionFee(accountsSuitableToPayForTXFeeRequest)

			let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

			let maybeFeePayer: FeePayerCandiate? = try await { () async throws -> FeePayerCandiate? in

				guard let accountInvolvedInTransactionWithEnoughBalance = await firstAccountAddressWithEnoughFunds(
					from: Array(accountAddressesSuitableToPayTransactionFeeRef),
					toPay: feeToAdd
				) else {
					return nil
				}

				guard let account = allAccounts.first(where: { $0.address == accountInvolvedInTransactionWithEnoughBalance.owner }) else {
					assertionFailure("Failed to find account, this should never happen.")
					throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
				}
				return FeePayerCandiate(account: account, xrdBalance: accountInvolvedInTransactionWithEnoughBalance.amount)
			}()

			guard let feePayer = maybeFeePayer else {
				// The transaction manifest does not reference any accounts that also has enough balance.
				// let us find some candidates accounts that user can select from
				let allAccountAddresses = allAccounts.map(\.address)
				let allAddressSet = Set(allAccountAddresses)
				let accountsNotAlreadyChecked = allAddressSet.subtracting(accountAddressesSuitableToPayTransactionFeeRef)

				let candidates = await accountsWithEnoughFunds(
					from: .init(accountsNotAlreadyChecked),
					toPay: feeToAdd
				)

				guard let nonEmpty = NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>.init(
					rawValue: .init(
						uniqueElements: candidates.compactMap { element in
							guard let account = allAccounts.first(where: { $0.address == element.owner }) else {
								return nil
							}
							return FeePayerCandiate(account: account, xrdBalance: element.amount)
						},
						id: \.id
					)
				) else {
					throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
				}

				return .excludesLockFee(
					maybeStringManifest,
					feePayerCandidates: nonEmpty,
					feeNotYetAdded: feeToAdd
				)
			}

			let manifestWithLockFee = try await lockFeeWithSelectedPayer(maybeStringManifest, feeToAdd, feePayer.account.address)
			return .includesLockFee(manifestWithLockFee, feeAdded: feeToAdd, feePayer: feePayer)
		}

		let buildTransactionIntent: BuildTransactionIntent = { request in
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch: Epoch
			do {
				epoch = try await gatewayAPIClient.getEpoch()
			} catch {
				return .failure(.failedToGetEpoch)
			}

			let version = engineToolkitClient.getTransactionVersion()

			let networkID = request.networkID
			let manifest = request.manifest
			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			let notaryAndSigners: NotaryAndSigners
			do {
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
				notaryAndSigners = .init(notarySigner: notary, accountsNeededToSign: accountsNeededToSign)
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

			var accountsToSignPublicKeys: [Engine.PublicKey] = []
			do {
				for account in notaryAndSigners.accountsNeededToSign {
					switch account.securityState {
					case let .unsecured(unsecuredControl):
						let key = try unsecuredControl.genesisFactorInstance.publicKey.intoEngine()
						accountsToSignPublicKeys.append(key)
					}
				}
			} catch {
				return .failure(.failedToLoadSignerPublicKeys)
			}

			let makeTransactionHeaderInput = request.makeTransactionHeaderInput

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

			return .success(.init(intent: intent, notaryAndSigners: notaryAndSigners, signerPublicKeys: accountsToSignPublicKeys))
		}

		// TODO: Should the request manifest have lockFee?
		let getTransactionPreview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			return await createTransactionPreviewRequest(for: request, networkID: networkID)
				.mapError {
					TransactionFailure.failedToPrepareTXReview(.failedSigning($0))
				}
				.asyncFlatMap { transactionPreviewRequest in
					do {
						let response = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
						guard response.receipt.status == .succeeded else {
							return .failure(
								TransactionFailure.failedToPrepareTXReview(
									.failedToRetrieveTXReceipt(response.receipt.errorMessage ?? "Unknown reason")
								)
							)
						}
						return .success(response)
					} catch {
						return .failure(TransactionFailure.failedToPrepareTXReview(.failedToRetrieveTXPreview(error)))
					}
				}
				.flatMap { (response: GatewayAPI.TransactionPreviewResponse) in
					do {
						let bytes = try [UInt8](hex: response.encodedReceipt)
						return .success(bytes)
					} catch {
						return .failure(TransactionFailure.failedToPrepareTXReview(.failedToExtractTXReceiptBytes(error)))
					}
				}
				.flatMap { (receiptBytes: [UInt8]) in
					let generateTransactionReviewRequest = AnalyzeManifestWithPreviewContextRequest(
						networkId: networkID,
						manifest: request.manifestToSign,
						transactionReceipt: receiptBytes
					)
					do {
						let analyzedManifestToReview = try engineToolkitClient.generateTransactionReview(generateTransactionReviewRequest)
						return .success(analyzedManifestToReview)
					} catch {
						return .failure(TransactionFailure.failedToPrepareTXReview(.failedToGenerateTXReview(error)))
					}
				}
				.asyncFlatMap { (analyzedManifestToReview: AnalyzeManifestWithPreviewContextResponse) in
					do {
						let addFeeToManifestOutcome = try await lockFeeBySearchingForSuitablePayer(request.manifestToSign, request.feeToAdd)
						let review = TransactionToReview(
							analyzedManifestToReview: analyzedManifestToReview,
							addFeeToManifestOutcome: addFeeToManifestOutcome,
							networkID: networkID
						)
						return .success(review)
					} catch {
						return .failure(.failedToPrepareTXReview(.failedToGenerateTXReview(error)))
					}
				}
		}

		@Sendable
		func createTransactionPreviewRequest(
			for request: ManifestReviewRequest,
			networkID: NetworkID
		) async -> Result<GatewayAPI.TransactionPreviewRequest, TransactionFailure.FailedToPrepareForTXSigning> {
			await buildTransactionIntent(.init(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				selectNotary: request.selectNotary
			)).map {
				GatewayAPI.TransactionPreviewRequest(
					rawManifest: request.manifestToSign,
					header: $0.intent.header,
					signerPublicKeys: $0.signerPublicKeys
				)
			}
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
			buildTransactionIntent: buildTransactionIntent
		)
	}
}

// MARK: - NotaryAndSigners
public struct NotaryAndSigners: Sendable, Hashable {
	/// Notary signer
	public let notarySigner: Profile.Network.Account
	/// Never empty, since this also contains the notary signer.
	public let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>>
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
