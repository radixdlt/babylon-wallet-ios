import AccountPortfoliosClient
import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import GatewayAPI
import GatewaysClient
import PersonasClient
import Resources

// MARK: - MyEntitiesInvolvedInTransaction
public struct MyEntitiesInvolvedInTransaction: Sendable, Hashable {
	/// A set of all MY personas or accounts in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	public var entitiesRequiringAuth: OrderedSet<Signer.Entity> {
		OrderedSet(accountsRequiringAuth.map { .account($0) } + identitiesRequiringAuth.map { .persona($0) })
	}

	public let identitiesRequiringAuth: OrderedSet<Profile.Network.Persona>
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
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

		@Sendable
		func myEntitiesInvolvedInTransaction(
			networkID: NetworkID,
			manifest: TransactionManifest
		) async throws -> MyEntitiesInvolvedInTransaction {
			let analyzed = try engineToolkitClient.analyzeManifest(.init(manifest: manifest, networkID: networkID))
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)

			func accountFromComponentAddress(_ componentAddress: ComponentAddress) -> Profile.Network.Account? {
				allAccounts.first(where: { $0.address.address == componentAddress.address })
			}
			func identityFromComponentAddress(_ componentAddress: ComponentAddress) -> Profile.Network.Persona {
				try await personasClient.getPersona(id: IdentityAddress(address: componentAddress.address))
			}
			func mapAccount(_ keyPath: KeyPath<AnalyzeManifestResponse, [ComponentAddress]>) throws -> OrderedSet<Profile.Network.Account> {
				try .init(validating: analyzed[keyPath: keyPath].compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ keyPath: KeyPath<AnalyzeManifestResponse, [ComponentAddress]>) throws -> OrderedSet<Profile.Network.Persona> {
				try .init(validating: analyzed[keyPath: keyPath].map(identityFromComponentAddress))
			}

			return try await MyEntitiesInvolvedInTransaction(
				identitiesRequiringAuth: mapIdentity(\.identitiesRequiringAuth),
				accountsRequiringAuth: mapAccount(\.accountsRequiringAuth),
				accountsWithdrawnFrom: mapAccount(\.accountsWithdrawnFrom),
				accountsDepositedInto: mapAccount(\.accountsDepositedInto)
			)
		}

		@Sendable
		func getTransactionSigners(_ request: BuildTransactionIntentRequest) async throws -> TransactionSigners {
			let myInvolvedEntities = try await myEntitiesInvolvedInTransaction(
				networkID: request.networkID,
				manifest: request.manifest
			)

			let intentSigning: TransactionSigners.IntentSigning = {
				if let nonEmpty = NonEmpty(rawValue: myInvolvedEntities.entitiesRequiringAuth) {
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
			let myInvolvedEntities = try await myEntitiesInvolvedInTransaction(
				networkID: networkID,
				manifest: manifest
			)

			loggerGlobal.debug("My involved entities: \(myInvolvedEntities)")
			var triedAccounts: Set<Profile.Network.Account> = []

			func findFeePayer(
				amongst keyPath: KeyPath<MyEntitiesInvolvedInTransaction, OrderedSet<Profile.Network.Account>>
			) async throws -> AddFeeToManifestOutcomeIncludesLockFee? {
				let accountsToCheck = myInvolvedEntities[keyPath: keyPath]
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
					feePayerSelectionAmongstCandidates: .init(
						selected: feePayer,
						candidates: nonEmpty,
						fee: feeToAdd,
						selection: .auto
					)
				)
			}

			// First try amonst `accountsWithdrawnFrom`
			if let withLockFee = try await findFeePayer(amongst: \.accountsWithdrawnFrom) {
				loggerGlobal.debug("Find suitable fee payer in: 'accountsWithdrawnFrom', specifically: \(withLockFee.feePayerSelectionAmongstCandidates.selected)")
				return .includesLockFee(withLockFee)
			}
			// no candiates amonst `accountsWithdrawnFrom` => fallback to `accountsRequiringAuth`
			if let withLockFee = try await findFeePayer(amongst: \.accountsRequiringAuth) {
				loggerGlobal.debug("Find suitable fee payer in: 'accountsRequiringAuth', specifically: \(withLockFee.feePayerSelectionAmongstCandidates.selected)")
				return .includesLockFee(withLockFee)
			}
			// no candiates amonst `accountsRequiringAuth` => fallback to `accountsDepositedInto`
			if let withLockFee = try await findFeePayer(amongst: \.accountsDepositedInto) {
				loggerGlobal.debug("Find suitable fee payer in: 'accountsDepositedInto', specifically: \(withLockFee.feePayerSelectionAmongstCandidates.selected)")
				return .includesLockFee(withLockFee)
			}
			loggerGlobal.debug("Did not find any suitable fee payer, retrieving candidates for user selection....")

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

		let addInstructionToManifest: AddInstructionToManifest = { request in
			let manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(request.manifest)
			var instructions = manifestWithJSONInstructions.instructions
			let new = request.instruction
			switch request.location {
			case .first:
				instructions.insert(new, at: 0)
			}
			return TransactionManifest(
				instructions: instructions,
				blobs: request.manifest.blobs
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
			addInstructionToManifest: addInstructionToManifest,
			addGuaranteesToManifest: addGuaranteesToManifest,
			getTransactionReview: getTransactionPreview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction
		)
	}
}
