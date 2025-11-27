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

extension MyEntitiesInvolvedInTransaction {
	static func fromInput(
		allAccounts: [Account],
		allPersonas: [Persona],
		addressesOfPersonasRequiringAuth: [IdentityAddress],
		addressesOfAccountsRequiringAuth: [AccountAddress],
		addressesOfAccountsWithdrawnFrom: any Collection<AccountAddress>,
		addressesOfAccountsDepositedInto: any Collection<AccountAddress>
	) throws -> Self {
		func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Account? {
			allAccounts.first { $0.address == accountAddress }
		}

		func identityFromComponentAddress(_ identityAddress: IdentityAddress) -> Persona? {
			allPersonas.first { $0.address == identityAddress }
		}

		func mapAccount(_ addresses: any Collection<AccountAddress>) throws -> OrderedSet<Account> {
			try .init(validating: addresses.compactMap(accountFromComponentAddress))
		}

		func mapIdentity(_ addresses: any Collection<IdentityAddress>) throws -> OrderedSet<Persona> {
			try .init(validating: addresses.compactMap(identityFromComponentAddress))
		}

		return try MyEntitiesInvolvedInTransaction(
			identitiesRequiringAuth: mapIdentity(addressesOfPersonasRequiringAuth),
			accountsRequiringAuth: mapAccount(addressesOfAccountsRequiringAuth),
			accountsWithdrawnFrom: mapAccount(addressesOfAccountsWithdrawnFrom),
			accountsDepositedInto: mapAccount(addressesOfAccountsDepositedInto)
		)
	}

	static func fromTransactionManifest(
		allAccounts: [Account],
		allPersonas: [Persona],
		manifest: TransactionManifest
	) throws -> Self {
		try fromInput(
			allAccounts: allAccounts,
			allPersonas: allPersonas,
			addressesOfPersonasRequiringAuth: manifest.summary.addressesOfPersonasRequiringAuth,
			addressesOfAccountsRequiringAuth: manifest.summary.addressesOfAccountsRequiringAuth,
			addressesOfAccountsWithdrawnFrom: manifest.summary.addressesOfAccountsWithdrawnFrom,
			addressesOfAccountsDepositedInto: manifest.summary.addressesOfAccountsDepositedInto
		)
	}

	static func fromExecutionSummary(
		allAccounts: [Account],
		allPersonas: [Persona],
		executionSummary: ExecutionSummary
	) throws -> Self {
		let addressOfSecurifiedEntity: AddressOfAccountOrPersona? = switch executionSummary.detailedClassification {
		case let .accessControllerRecovery(acAddresses), let .accessControllerConfirmTimedRecovery(acAddresses), let .accessControllerStopTimedRecovery(acAddresses):
			try? SargonOs.shared.entityByAccessControllerAddress(address: acAddresses.first!).address
		default:
			nil
		}

		let additionalAccountsRequiringAuth: [AccountAddress] = if let addressOfSecurifiedEntity, case let .account(accountAddress) = addressOfSecurifiedEntity {
			[accountAddress]
		} else {
			[]
		}

		let additionalPersonasRequiringAuth: [IdentityAddress] = if let addressOfSecurifiedEntity, case let .identity(identityAddress) = addressOfSecurifiedEntity {
			[identityAddress]
		} else {
			[]
		}

		return try fromInput(
			allAccounts: allAccounts,
			allPersonas: allPersonas,
			addressesOfPersonasRequiringAuth: executionSummary.addressesOfIdentitiesRequiringAuth + additionalPersonasRequiringAuth,
			addressesOfAccountsRequiringAuth: executionSummary.addressesOfAccountsRequiringAuth + additionalAccountsRequiringAuth,
			addressesOfAccountsWithdrawnFrom: executionSummary.withdrawals.keys,
			addressesOfAccountsDepositedInto: executionSummary.deposits.keys
		)
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
			let allPersonas = await personasClient.getPersonasOnNetwork(networkID)

			return try MyEntitiesInvolvedInTransaction.fromTransactionManifest(
				allAccounts: allAccounts.elements,
				allPersonas: allPersonas.elements,
				manifest: manifest
			)
		}

		@Sendable
		func myEntitiesInvolvedInTransaction(
			networkID: NetworkID,
			executionSummary: ExecutionSummary
		) async throws -> MyEntitiesInvolvedInTransaction {
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)
			let allPersonas = await personasClient.getPersonasOnNetwork(networkID)

			return try MyEntitiesInvolvedInTransaction.fromExecutionSummary(
				allAccounts: allAccounts.elements,
				allPersonas: allPersonas.elements,
				executionSummary: executionSummary
			)
		}

		@Sendable
		func getTransactionSigners(_ request: GetTransactionSignersRequest) async throws -> TransactionSigners {
			let myInvolvedEntities = try await myEntitiesInvolvedInTransaction(
				networkID: request.networkID,
				executionSummary: request.executionSummary
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
		func getFeePayerCandidates(refreshingBalances: Bool, accounts: Accounts) async throws -> IdentifiedArrayOf<FeePayerCandidate> {
			let networkId = await gatewaysClient.getCurrentNetworkID()
			let xrdAddress: ResourceAddress = .xrd(on: networkId)
			let xrdVaults = await accounts.concurrentCompactMap { acc in
				try? await gatewayAPIClient.getEntityFungibleResourceVaultsPage(.init(address: acc.address.address, resourceAddress: xrdAddress.address))
			}

			let allFeePayerCandidates = accounts.compactMap { account -> FeePayerCandidate? in
				guard let xrdVault = xrdVaults.first(where: { $0.address == account.address.address }) else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}

				guard let xrdBalanceRaw = xrdVault.items.first?.amount,
				      let xrdBalance = try? Decimal192(xrdBalanceRaw)
				else {
					return nil
				}

				return FeePayerCandidate(account: account, xrdBalance: xrdBalance)
			}

			return allFeePayerCandidates.asIdentified()
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
			let signedIntentHash = request.signedIntent.hash()

			let notarySignature = try request.notary.signature(for: signedIntentHash.hash.data)

			let notarizedTransaction = try NotarizedTransaction(
				signedIntent: request.signedIntent,
				notarySignature: NotarySignature(signature: .ed25519(value: .init(bytes: .init(bytes: notarySignature))))
			)

			let intent = request.signedIntent.intent
			let txID = intent.hash()

			return .init(
				notarized: notarizedTransaction,
				intent: intent,
				txID: txID
			)
		}

		@Sendable
		func analyseTransactionPreview(request: ManifestReviewRequest) async throws -> Sargon.TransactionToReview {
			do {
				return try await SargonOS.shared.analyseTransactionPreview(
					instructions: request.unvalidatedManifest.transactionManifestString,
					blobs: request.unvalidatedManifest.blobs,
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
				executionSummary: preview.executionSummary,
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
			let involvedEntites = try await myEntitiesInvolvedInTransaction(
				networkID: request.networkId,
				executionSummary: request.executionSummary
			)
			let accounts = involvedEntites.accountsDepositedInto.elements + involvedEntites.accountsWithdrawnFrom.elements + involvedEntites.accountsRequiringAuth.elements
			let feePayerCandidates = try await getFeePayerCandidates(refreshingBalances: true, accounts: accounts.asIdentified())

			/// Select the account that can pay the transaction fee
			return try await feePayerSelectionAmongstCandidates(
				request: request,
				feePayerCandidates: feePayerCandidates,
				involvedEntities: involvedEntites,
				accountWithdraws: request.executionSummary.withdrawals
			)
		}

		return Self(
			getTransactionReview: getTransactionReview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction,
			myInvolvedEntities: myInvolvedEntities,
			determineFeePayer: determineFeePayer,
			getFeePayerCandidates: { refresh in
				let networkID = await gatewaysClient.getCurrentNetworkID()
				let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)
				return try await getFeePayerCandidates(refreshingBalances: refresh, accounts: allAccounts)
			}
		)
	}
}

extension TransactionClient {
	@Sendable
	static func feePayerSelectionAmongstCandidates(
		request: DetermineFeePayerRequest,
		feePayerCandidates: IdentifiedArrayOf<FeePayerCandidate>,
		involvedEntities: MyEntitiesInvolvedInTransaction,
		accountWithdraws: [AccountAddress: [ResourceIndicator]]
	) async throws -> FeePayerSelectionResult? {
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let totalCost = request.transactionFee.totalFee.max
		let allSignerEntities = request.transactionSigners.intentSignerEntitiesOrEmpty()

		if case let .accessControllerRecovery(acAddresses) = request.executionSummary.detailedClassification, let acAddress = acAddresses.first {
			@Dependency(\.accessControllerClient) var accessControllerClient
			let details = try await accessControllerClient.getAccessControllerStateDetails(acAddress)
			if let feePayerCandidate = feePayerCandidates.first, details.xrdBalance >= totalCost {
				return .init(
					payer: feePayerCandidate,
					updatedFee: request.transactionFee,
					transactionSigners: request.transactionSigners,
					signingFactors: request.signingFactors
				)
			} else {
				return nil
			}
		}

		func findFeePayer(
			amongst keyPath: KeyPath<MyEntitiesInvolvedInTransaction, OrderedSet<Account>>,
			includeSignaturesCost: Bool
		) async throws -> FeePayerSelectionResult? {
			let accountsToCheck = involvedEntities[keyPath: keyPath]
			let candidates = feePayerCandidates.filter {
				accountsToCheck.contains($0.account)
			}

			for candidate in candidates {
				let candidateXRDWithdraw = accountWithdraws[candidate.account.address]?
					.first(where: \.resourceAddress.isXRD)?
					.guaranteedFungibleAmount ?? .zero

				if request.transactionSigners.intentSignerEntitiesOrEmpty().contains(.account(candidate.account)) {
					/// The cost of the fee payer signature is already accounted for.
					if candidate.xrdBalance >= totalCost + candidateXRDWithdraw {
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
				if candidate.xrdBalance >= feeIncludingCandidate.totalFee.max + candidateXRDWithdraw {
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

		case let .FailedTransactionPreview(message):
			.failedToPrepareTXReview(.failedTXPreview(message))

		case .FailedToExtractTransactionReceiptBytes:
			.failedToPrepareTXReview(.failedToExtractTXReceiptBytes)

		case let .ExecutionSummaryFail(underlying):
			.failedToPrepareTXReview(.failedTXPreview(underlying))

		case let .FailedToGenerateManifestSummary(underlying):
			.failedToPrepareTXReview(.failedTXPreview(underlying))

		case let .InvalidInstructionsString(underlying):
			.failedToPrepareTXReview(.failedTXPreview(underlying))

		case let .some(err):
			.failedToPrepareTXReview(.failedTXPreview(errorMessageFromError(error: err)))

		default:
			.failedToPrepareTXReview(.failedTXPreview("Unknown reason"))
		}
	}
}

extension ResourceIndicator {
	var guaranteedFungibleAmount: Decimal192? {
		switch self {
		case let .fungible(_, .guaranteed(value)): value
		case .fungible(_, .predicted): nil
		case .nonFungible: nil
		}
	}
}
