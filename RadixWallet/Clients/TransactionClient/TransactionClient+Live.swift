// MARK: - MyEntitiesInvolvedInTransaction
struct MyEntitiesInvolvedInTransaction: Sendable, Hashable {
	/// A set of all MY personas or accounts in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	var entitiesRequiringAuth: OrderedSet<AccountOrPersona> {
		OrderedSet(accountsRequiringAuth.map { .account($0) } + identitiesRequiringAuth.map { .persona($0) })
	}

	let identitiesRequiringAuth: OrderedSet<Persona>
	let accountsRequiringAuth: OrderedSet<Account>

	/// A set of all MY accounts in the manifest which were deposited into. This is a subset of the addresses seen in `accountsRequiringAuth`.
	let accountsWithdrawnFrom: OrderedSet<Account>

	/// A set of all MY accounts in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	let accountsDepositedInto: OrderedSet<Account>

	init(
		identitiesRequiringAuth: OrderedSet<Persona>,
		accountsRequiringAuth: OrderedSet<Account>,
		accountsWithdrawnFrom: OrderedSet<Account>,
		accountsDepositedInto: OrderedSet<Account>
	) {
		self.identitiesRequiringAuth = identitiesRequiringAuth
		self.accountsRequiringAuth = accountsRequiringAuth
		self.accountsWithdrawnFrom = accountsWithdrawnFrom
		self.accountsDepositedInto = accountsDepositedInto
	}
}

extension TransactionClient {
	struct NoFeePayerCandidate: LocalizedError {
		var errorDescription: String? { "No account containing XRD found" }
	}

	static var liveValue: Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable
		func myEntitiesInvolvedInTransaction(
			networkID: NetworkID,
			manifest: TransactionManifest
		) async throws -> MyEntitiesInvolvedInTransaction {
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)

			func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Account? {
				allAccounts.first { $0.address == accountAddress }
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ addresses: [AccountAddress]) throws -> OrderedSet<Account> {
				try .init(validating: addresses.compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ addresses: [IdentityAddress]) async throws -> OrderedSet<Persona> {
				try await .init(validating: addresses.asyncMap(identityFromComponentAddress))
			}

			let summary = manifest.summary

			return try await MyEntitiesInvolvedInTransaction(
				identitiesRequiringAuth: mapIdentity(summary.addressesOfPersonasRequiringAuth),
				accountsRequiringAuth: mapAccount(summary.addressesOfAccountsRequiringAuth),
				accountsWithdrawnFrom: mapAccount(summary.addressesOfAccountsWithdrawnFrom),
				accountsDepositedInto: mapAccount(summary.addressesOfAccountsDepositedInto)
			)
		}

		@Sendable
		func getTransactionSigners(_ request: GetTransactionSignersRequest) async throws -> TransactionSigners {
			let myInvolvedEntities = try await myEntitiesInvolvedInTransaction(
				networkID: request.networkID,
				manifest: request.manifest
			)

			let intentSigning: TransactionSigners.IntentSigning = if let nonEmpty = NonEmpty(rawValue: myInvolvedEntities.entitiesRequiringAuth) {
				.intentSigners(nonEmpty)
			} else {
				.notaryIsSignatory
			}

			return .init(
				notaryPublicKey: request.ephemeralNotaryPublicKey,
				intentSigning: intentSigning
			)
		}

		@Sendable
		func getAllFeePayerCandidates(refreshingBalances: Bool) async throws -> NonEmpty<IdentifiedArrayOf<FeePayerCandidate>> {
			let networkID = await gatewaysClient.getCurrentNetworkID()
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)
			let entities = try await onLedgerEntitiesClient.getAccounts(allAccounts.map(\.address), cachingStrategy: .forceUpdate)

			let allFeePayerCandidates = allAccounts.compactMap { account -> FeePayerCandidate? in
				guard let entity = entities.first(where: { $0.address == account.address }) else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}

				guard let xrdBalance = entity.fungibleResources.xrdResource?.amount else {
					return nil
				}

				return FeePayerCandidate(account: account, xrdBalance: xrdBalance.nominalAmount)
			}

			guard let allCandidates = NonEmpty(rawValue: IdentifiedArray(uncheckedUniqueElements: allFeePayerCandidates)) else {
				throw NoFeePayerCandidate()
			}

			return allCandidates
		}

		let buildTransactionIntent: BuildTransactionIntent = { request in
			let epoch = try await gatewayAPIClient.getEpoch()

			let header = TransactionHeader(
				networkId: request.networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + request.makeTransactionHeaderInput.epochWindow,
				nonce: request.nonce,
				notaryPublicKey: Sargon.PublicKey.ed25519(request.transactionSigners.notaryPublicKey.intoSargon()),
				notaryIsSignatory: request.transactionSigners.notaryIsSignatory,
				tipPercentage: request.makeTransactionHeaderInput.tipPercentage
			)

			return .init(header: header, manifest: request.manifest, message: request.message)
		}

		let notarizeTransaction: NotarizeTransaction = { request in
			let signedTransactionIntent = SignedIntent(
				intent: request.transactionIntent,
				intentSignatures: IntentSignatures(signatures: Array(request.intentSignatures.map { IntentSignature(signatureWithPublicKey: $0) }))
			)

			let signedIntentHash = signedTransactionIntent.hash()

			let notarySignature = try request.notary.signature(for: signedIntentHash.hash.data)

			let notarizedTransaction = try NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: NotarySignature(signature: .ed25519(value: .init(bytes: .init(bytes: notarySignature))))
			)

			let txID = request.transactionIntent.hash()

			return .init(
				notarized: notarizedTransaction,
				intent: request.transactionIntent,
				txID: txID
			)
		}

		@Sendable
		func analyseTransactionPreview(request: ManifestReviewRequest) async throws -> Sargon.TransactionToReview {
			do {
				return try await SargonOS.shared.analyseTransactionPreview(
					instructions: request.unvalidatedManifest.transactionManifestString,
					blobs: request.unvalidatedManifest.blobs,
					message: request.message,
					areInstructionsOriginatingFromHost: request.isWalletTransaction,
					nonce: request.nonce,
					notaryPublicKey: .ed25519(request.ephemeralNotaryPublicKey.intoSargon())
				)
			} catch {
				throw TransactionFailure.fromCommonError(error as? CommonError)
			}
		}

		let getTransactionReview: GetTransactionReview = { request in
			// Get preview from SargonOS
			let preview = try await analyseTransactionPreview(request: request)

			let networkID = await gatewaysClient.getCurrentNetworkID()

			/// Get all transaction signers.
			let transactionSigners = try await getTransactionSigners(.init(
				networkID: networkID,
				manifest: preview.transactionManifest,
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			/// Get all of the expected signing factors.
			let signingFactors = try await {
				if let nonEmpty = NonEmpty<Set<AccountOrPersona>>(transactionSigners.intentSignerEntitiesOrEmpty()) {
					return try await factorSourcesClient.getSigningFactors(.init(
						networkID: networkID,
						signers: nonEmpty,
						signingPurpose: request.signingPurpose
					))
				}
				return [:]
			}()

			/// If notary is signatory, count the signature of the notary that will be added.
			let signaturesCount = transactionSigners.notaryIsSignatory ? 1 : signingFactors.expectedSignatureCount
			var transactionFee = try TransactionFee(
				executionSummary: preview.executionSummary,
				signaturesCount: signaturesCount,
				notaryIsSignatory: transactionSigners.notaryIsSignatory,
				includeLockFee: false // Calculate without LockFee cost. It is yet to be determined if LockFe will be added or not
			)

			if transactionFee.totalFee.lockFee > .zero {
				/// LockFee required
				/// Total cost > `zero`, recalculate the total by adding lockFee cost.
				transactionFee.addLockFeeCost()
				/// Fee Payer is required, thus there will be a signature with user account added
				transactionFee.updateNotarizingCost(notaryIsSignatory: false)
			}

			return TransactionToReview(
				transactionManifest: preview.transactionManifest,
				analyzedManifestToReview: preview.executionSummary,
				networkID: networkID,
				transactionFee: transactionFee,
				transactionSigners: transactionSigners,
				signingFactors: signingFactors
			)
		}

		let myInvolvedEntities: MyInvolvedEntities = { manifest in
			let networkID = await gatewaysClient.getCurrentNetworkID()
			return try await myEntitiesInvolvedInTransaction(
				networkID: networkID,
				manifest: manifest
			)
		}

		let determineFeePayer: DetermineFeePayer = { request in
			let feePayerCandidates = try await getAllFeePayerCandidates(refreshingBalances: true)
			let involvedEntites = try await myEntitiesInvolvedInTransaction(
				networkID: request.networkId,
				manifest: request.manifest
			)

			/// Select the account that can pay the transaction fee
			return try await feePayerSelectionAmongstCandidates(
				request: request,
				allFeePayerCandidates: feePayerCandidates,
				involvedEntities: involvedEntites
			)
		}

		return Self(
			getTransactionReview: getTransactionReview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction,
			myInvolvedEntities: myInvolvedEntities,
			determineFeePayer: determineFeePayer,
			getFeePayerCandidates: { refresh in
				try await getAllFeePayerCandidates(refreshingBalances: refresh)
			}
		)
	}
}

extension TransactionClient {
	@Sendable
	static func feePayerSelectionAmongstCandidates(
		request: DetermineFeePayerRequest,
		allFeePayerCandidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>,
		involvedEntities: MyEntitiesInvolvedInTransaction
	) async throws -> FeePayerSelectionResult? {
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let totalCost = request.transactionFee.totalFee.max
		let allSignerEntities = request.transactionSigners.intentSignerEntitiesOrEmpty()

		func findFeePayer(
			amongst keyPath: KeyPath<MyEntitiesInvolvedInTransaction, OrderedSet<Account>>,
			includeSignaturesCost: Bool
		) async throws -> FeePayerSelectionResult? {
			let accountsToCheck = involvedEntities[keyPath: keyPath]
			let candidates = allFeePayerCandidates.filter {
				accountsToCheck.contains($0.account)
			}

			for candidate in candidates {
				if request.transactionSigners.intentSignerEntitiesOrEmpty().contains(.account(candidate.account)) {
					/// The cost of the fee payer signature is already accounted for.
					if candidate.xrdBalance >= totalCost {
						return .init(
							payer: candidate,
							updatedFee: request.transactionFee,
							transactionSigners: request.transactionSigners,
							signingFactors: request.signingFactors
						)
					}
				}

				/// We do have the base fee calculated with the signatures cost for `accountsRequiringAuth`.
				/// However, if we are to select a fee payer outside of the `accountsRequiringAuth` it is needed:
				/// - Include the fee payer account as signer
				/// - Update the signingFactors to contain the factors for the fee payer.
				/// - Recalculate the fee by taking into account the new signature cost.
				/// - Makes sure that the account can pay for the base fee + the fee for its signature.

				let signerEntities = allSignerEntities + [.account(candidate.account)]
				let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
					networkID: request.networkId,
					signers: .init(rawValue: Set(signerEntities))!,
					signingPurpose: request.signingPurpose
				))

				var feeIncludingCandidate = request.transactionFee
				feeIncludingCandidate.updateSignaturesCost(signingFactors.expectedSignatureCount)
				if candidate.xrdBalance >= feeIncludingCandidate.totalFee.max {
					let signers = TransactionSigners(
						notaryPublicKey: request.transactionSigners.notaryPublicKey,
						intentSigning: .intentSigners(.init(rawValue: .init(signerEntities))!)
					)
					return .init(
						payer: candidate,
						updatedFee: feeIncludingCandidate,
						transactionSigners: signers,
						signingFactors: signingFactors
					)
				}
			}
			return nil
		}

		// First try amongst `accountsWithdrawnFrom`
		if let result = try await findFeePayer(amongst: \.accountsWithdrawnFrom, includeSignaturesCost: true) {
			loggerGlobal.debug("Found suitable fee payer in: 'accountsWithdrawnFrom', specifically: \(result.payer)")
			return result
		}

		// no candidates amongst `accountsWithdrawnFrom` => fallback to `accountsDepositedInto`
		if let result = try await findFeePayer(amongst: \.accountsDepositedInto, includeSignaturesCost: true) {
			loggerGlobal.debug("Found suitable fee payer in: 'accountsDepositedInto', specifically: \(result.payer)")
			return result
		}

		// no candidates amongst `accountsDepositedInto` => fallback to `accountsRequiringAuth`
		if let result = try await findFeePayer(amongst: \.accountsRequiringAuth, includeSignaturesCost: false) {
			loggerGlobal.debug("Found suitable fee payer in: 'accountsRequiringAuth', specifically: \(result.payer)")
			return result
		}

		loggerGlobal.notice("Did not find any suitable fee payer, retrieving candidates for user selection....")
		return nil
	}
}

extension TransactionFailure {
	static func fromCommonError(_ commonError: CommonError?) -> Self {
		switch commonError {
		case let .ReservedInstructionsNotAllowedInManifest(reservedInstructions):
			.failedToPrepareTXReview(.manifestWithReservedInstructions(reservedInstructions))

		case .OneOfReceivingAccountsDoesNotAllowDeposits:
			.failedToPrepareTXReview(.oneOfRecevingAccountsDoesNotAllowDeposits)

		case .FailedTransactionPreview:
			.failedToPrepareTXReview(.failedToRetrieveTXReceipt("Unknown reason"))

		case .FailedToExtractTransactionReceiptBytes:
			.failedToPrepareTXReview(.failedToExtractTXReceiptBytes)

		default:
			.failedToPrepareTXReview(.failedToRetrieveTXReceipt("Unknown reason"))
		}
	}
}
