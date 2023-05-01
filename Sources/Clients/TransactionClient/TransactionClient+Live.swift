import AccountPortfoliosClient
import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import GatewayAPI
import GatewaysClient
import Resources

// MARK: - FailedToFindReferencedAccount
struct FailedToFindReferencedAccount: Swift.Error {}

// MARK: - AccountNotFoundHandlingStrategy
enum AccountNotFoundHandlingStrategy {
	case throwError
	case skip
	case regardAsNotMine
}

// MARK: - AccountsInvolvedInTransaction
public struct AccountsInvolvedInTransaction: Sendable, Hashable {
	public enum AccountType: Sendable, Hashable {
		case mine(Profile.Network.Account)
		case notMine(AccountAddress)
		func getMine() throws -> Profile.Network.Account {
			guard case let .mine(mine) = self else {
				throw FailedToFindReferencedAccount()
			}
			return mine
		}
	}

	/// A set of all of the account component addresses in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	public let accountsRequiringAuth: OrderedSet<AccountType>

	/// A set of all of the account component addresses in the manifest which were deposited into. This is a subset of the addresses seen in `accountsRequiringAuth`.
	public let accountsWithdrawnFrom: OrderedSet<AccountType>

	/// A set of all of the account component addresses in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	public let accountsDepositedInto: OrderedSet<AccountType>

	func getMine() throws -> MyAccountsInvolvedInTransaction {
		try .init(
			accountsRequiringAuth: .init(validating: accountsRequiringAuth.map { try $0.getMine() }), // for now assume we must have this
			accountsWithdrawnFrom: .init(validating: accountsRequiringAuth.compactMap { try? $0.getMine() }),
			accountsDepositedInto: .init(validating: accountsRequiringAuth.compactMap { try? $0.getMine() })
		)
	}
}

// MARK: - MyAccountsInvolvedInTransaction
public struct MyAccountsInvolvedInTransaction: Sendable, Hashable {
	/// A set of all MY accounts in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	public let accountsRequiringAuth: OrderedSet<Profile.Network.Account>

	/// A set of all MY accounts in the manifest which were deposited into. This is a subset of the addresses seen in `accountsRequiringAuth`.
	public let accountsWithdrawnFrom: OrderedSet<Profile.Network.Account>

	/// A set of all MY accounts in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	public let accountsDepositedInto: OrderedSet<Profile.Network.Account>
}

extension TransactionClient {
	public static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

		@Sendable
		func accountsInvolvedInTransaction(
			networkID: NetworkID,
			manifest: TransactionManifest,
			accountNotFoundHandlingStrategy: AccountNotFoundHandlingStrategy = .regardAsNotMine
		) async throws -> AccountsInvolvedInTransaction {
			let analyzed = try engineToolkitClient.analyzeManifest(.init(manifest: manifest, networkID: networkID))
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)

			func toAccount(
				_ address: AccountAddress
			) throws -> AccountsInvolvedInTransaction.AccountType? {
				if let account = allAccounts.first(where: { $0.address == address }) {
					return .mine(account)
				} else {
					switch accountNotFoundHandlingStrategy {
					case .throwError:
						throw FailedToFindReferencedAccount()
					case .skip:
						return nil
					case .regardAsNotMine:
						return .notMine(address)
					}
				}
			}

			return try AccountsInvolvedInTransaction(
				accountsRequiringAuth: .init(validating: analyzed.accountsRequiringAuth.compactMap { try toAccount($0) }),
				accountsWithdrawnFrom: .init(validating: analyzed.accountsWithdrawnFrom.compactMap { try toAccount($0) }),
				accountsDepositedInto: .init(validating: analyzed.accountsDepositedInto.compactMap { try toAccount($0) })
			)
		}

		@Sendable
		func getTransactionSigners(_ request: BuildTransactionIntentRequest) async throws -> TransactionSigners {
			let involvedAccounts = try await accountsInvolvedInTransaction(
				networkID: request.networkID,
				manifest: request.manifest,
				accountNotFoundHandlingStrategy: .regardAsNotMine
			)

			let myInvolvedAccounts = try involvedAccounts.getMine()

			let intentSigning: TransactionSigners.IntentSigning = {
				if let nonEmpty = NonEmpty(rawValue: myInvolvedAccounts.accountsRequiringAuth) {
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

		@Sendable
		func feePayerCandiates(
			accounts: OrderedSet<Profile.Network.Account>,
			fee: BigDecimal
		) async throws -> OrderedSet<FeePayerCandiate> {
			let portfolios = await accountsWithEnoughFunds(from: accounts.map(\.address), toPay: fee)
			return try .init(validating: portfolios.compactMap { tokenBalance in
				guard
					let account = accounts.first(where: { account in account.address == tokenBalance.owner }),
					let xrdBalance = tokenBalance.fungibleResources.xrdResource?.amount
				else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}
				return FeePayerCandiate(
					account: account,
					xrdBalance: xrdBalance
				)
			})
		}

		let convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString = { manifest in
			try await engineToolkitClient.convertManifestInstructionsToJSONIfItWasString(
				.init(
					version: engineToolkitClient.getTransactionVersion(),
					networkID: gatewaysClient.getCurrentNetworkID(),
					manifest: manifest
				)
			)
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

			return TransactionManifest(
				instructions: instructions,
				blobs: maybeStringManifest.blobs
			)
		}

		let lockFeeBySearchingForSuitablePayer: LockFeeBySearchingForSuitablePayer = { manifest, feeToAdd in
			let networkID = await gatewaysClient.getCurrentNetworkID()
			let involvedAccounts = try await accountsInvolvedInTransaction(
				networkID: networkID,
				manifest: manifest,
				accountNotFoundHandlingStrategy: .regardAsNotMine
			)

			let myInvolvedAccounts = try involvedAccounts.getMine()
			var triedAccounts: Set<Profile.Network.Account> = []
			func findFeePayer(
				amongst keyPath: KeyPath<MyAccountsInvolvedInTransaction, OrderedSet<Profile.Network.Account>>
			) async throws -> AddFeeToManifestOutcomeIncludesLockFee? {
				let accountsToCheck = myInvolvedAccounts[keyPath: keyPath]
				let involvedFeePayerCandidates = try await feePayerCandiates(
					accounts: accountsToCheck,
					fee: feeToAdd
				)
				triedAccounts.append(contentsOf: accountsToCheck)
				guard
					let nonEmpty = NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>(rawValue: .init(uncheckedUniqueElements: involvedFeePayerCandidates))
				else {
					return nil
				}

				let feePayer = nonEmpty.first
				let manifestWithLockFee = try await lockFeeWithSelectedPayer(
					manifest,
					feeToAdd, feePayer.account.address
				)

				return .init(
					manifestWithLockFee: manifestWithLockFee,
					feePayer: .init(
						selected: feePayer,
						candidates: nonEmpty,
						fee: feeToAdd,
						selection: .auto
					)
				)
			}

			// First try amonst `accountsWithdrawnFrom`
			if let withLockFee = try await findFeePayer(amongst: \.accountsWithdrawnFrom) {
				return .includesLockFee(withLockFee)
			}
			// no candiates amonst `accountsWithdrawnFrom` => fallback to `accountsRequiringAuth`
			if let withLockFee = try await findFeePayer(amongst: \.accountsRequiringAuth) {
				return .includesLockFee(withLockFee)
			}
			// no candiates amonst `accountsRequiringAuth` => fallback to `accountsDepositedInto`
			if let withLockFee = try await findFeePayer(amongst: \.accountsDepositedInto) {
				return .includesLockFee(withLockFee)
			}

			// None of the accounts in `myInvolvedAccounts` had any XRD, skip them all and fallback to fetching XRD for all other accounts on this
			// network that not part of `myInvolvedAccounts`.
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)

			let remainingAccounts = Set(allAccounts.rawValue.elements).subtracting(triedAccounts)
			let remainingCandidates = try await feePayerCandiates(accounts: .init(remainingAccounts), fee: feeToAdd)

			guard let nonEmpty = NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>(rawValue: .init(uncheckedUniqueElements: remainingCandidates)) else {
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
			}

			return .excludesLockFee(.init(manifestExcludingLockFee: manifest, feePayerCandidates: nonEmpty, feeNotYetAdded: feeToAdd))
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

			return .init(
				intent: .init(
					header: header,
					manifest: request.manifest
				),
				transactionSigners: transactionSigners
			)
		}

		let notarizeTransaction: NotarizeTransaction = { request in

			let intent = try engineToolkitClient.decompileTransactionIntent(.init(
				compiledIntent: request.compileTransactionIntent.compiledIntent,
				instructionsOutputKind: .parsed
			))

			let signedTransactionIntent = SignedTransactionIntent(
				intent: intent,
				intentSignatures: Array(request.intentSignatures)
			)
			let txID = try engineToolkitClient.generateTXID(intent)
			let compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(
				signedTransactionIntent
			)

			let notarySignature = try request.notary.sign(
				hashOfMessage: blake2b(data: compiledSignedIntent.compiledIntent)
			)

			let uncompiledNotarized = try NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature.intoEngine().signature
			)

			let compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(
				uncompiledNotarized
			)

			return .init(
				notarized: compiledNotarizedTXIntent,
				txID: txID
			)
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

			let analyzedManifestToReview = try engineToolkitClient.analyzeManifestWithPreviewContext(.init(
				networkId: networkID,
				manifest: request.manifestToSign,
				transactionReceipt: receiptBytes
			))

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
