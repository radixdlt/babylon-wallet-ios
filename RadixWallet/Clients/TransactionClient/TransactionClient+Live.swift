// MARK: - MyEntitiesInvolvedInTransaction
public struct MyEntitiesInvolvedInTransaction: Sendable, Hashable {
	/// A set of all MY personas or accounts in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	public var entitiesRequiringAuth: OrderedSet<EntityPotentiallyVirtual> {
		OrderedSet(accountsRequiringAuth.map { .account($0) } + identitiesRequiringAuth.map { .persona($0) })
	}

	public let identitiesRequiringAuth: OrderedSet<Profile.Network.Persona>
	public let accountsRequiringAuth: OrderedSet<Profile.Network.Account>

	/// A set of all MY accounts in the manifest which were deposited into. This is a subset of the addresses seen in `accountsRequiringAuth`.
	public let accountsWithdrawnFrom: OrderedSet<Profile.Network.Account>

	/// A set of all MY accounts in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	public let accountsDepositedInto: OrderedSet<Profile.Network.Account>

	public init(
		identitiesRequiringAuth: OrderedSet<Profile.Network.Persona>,
		accountsRequiringAuth: OrderedSet<Profile.Network.Account>,
		accountsWithdrawnFrom: OrderedSet<Profile.Network.Account>,
		accountsDepositedInto: OrderedSet<Profile.Network.Account>
	) {
		self.identitiesRequiringAuth = identitiesRequiringAuth
		self.accountsRequiringAuth = accountsRequiringAuth
		self.accountsWithdrawnFrom = accountsWithdrawnFrom
		self.accountsDepositedInto = accountsDepositedInto
	}
}

extension TransactionClient {
	public struct NoFeePayerCandidate: LocalizedError {
		public var errorDescription: String? { "No account containing XRD found" }
	}

	public static var liveValue: Self {
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

			func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Profile.Network.Account? {
				allAccounts.first { $0.address == accountAddress }
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Profile.Network.Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ addresses: [EngineToolkit.Address]) throws -> OrderedSet<Profile.Network.Account> {
				try .init(validating: addresses.asSpecific().compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ addresses: [EngineToolkit.Address]) async throws -> OrderedSet<Profile.Network.Persona> {
				try await .init(validating: addresses.asSpecific().asyncMap(identityFromComponentAddress))
			}

			let summary = manifest.summary(networkId: networkID.rawValue)

			return try await MyEntitiesInvolvedInTransaction(
				identitiesRequiringAuth: mapIdentity(summary.identitiesRequiringAuth),
				accountsRequiringAuth: mapAccount(summary.accountsRequiringAuth),
				accountsWithdrawnFrom: mapAccount(summary.accountsWithdrawnFrom),
				accountsDepositedInto: mapAccount(summary.accountsDepositedInto)
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

			let allFeePayerCandidates = try await onLedgerEntitiesClient.getAccounts(allAccounts.map(\.address), cachingStrategy: .forceUpdate).compactMap { portfolio -> FeePayerCandidate? in
				guard
					let account = allAccounts.first(where: { account in account.address == portfolio.address })
				else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}

				guard let xrdBalance = portfolio.fungibleResources.xrdResource?.amount else {
					return nil
				}

				return FeePayerCandidate(account: account, xrdBalance: xrdBalance)
			}

			guard let allCandidates = NonEmpty(rawValue: IdentifiedArray(uncheckedUniqueElements: allFeePayerCandidates)) else {
				throw NoFeePayerCandidate()
			}

			return allCandidates
		}

		let buildTransactionIntent: BuildTransactionIntent = { request in
			let epoch = try await gatewayAPIClient.getEpoch()

			let header = TransactionHeader(
				networkId: request.networkID.rawValue,
				startEpochInclusive: epoch.rawValue,
				endEpochExclusive: (epoch + request.makeTransactionHeaderInput.epochWindow).rawValue,
				nonce: request.nonce.rawValue,
				notaryPublicKey: SLIP10.PublicKey.eddsaEd25519(request.transactionSigners.notaryPublicKey).intoEngine(),
				notaryIsSignatory: request.transactionSigners.notaryIsSignatory,
				tipPercentage: request.makeTransactionHeaderInput.tipPercentage
			)

			return .init(header: header, manifest: request.manifest, message: request.message)
		}

		let notarizeTransaction: NotarizeTransaction = { request in
			let signedTransactionIntent = SignedIntent(
				intent: request.transactionIntent,
				intentSignatures: Array(request.intentSignatures)
			)

			let signedIntentHash = try signedTransactionIntent.signedIntentHash()

			let notarySignature = try request.notary.sign(
				hashOfMessage: signedIntentHash.bytes().data
			)

			let uncompiledNotarized = try NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature.intoEngine().signature
			)

			let compiledNotarizedTXIntent = try uncompiledNotarized.compile()

			let txID = try request.transactionIntent.intentHash()

			return .init(
				notarized: compiledNotarizedTXIntent,
				intent: request.transactionIntent,
				txID: txID
			)
		}

		let getTransactionReview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let manifestToSign = try request.unvalidatedManifest.transactionManifest(onNetwork: networkID)

			/// Get all transaction signers.
			let transactionSigners = try await getTransactionSigners(.init(
				networkID: networkID,
				manifest: manifestToSign,
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			/// Get the transaction preview
			let transactionPreviewRequest = try await createTransactionPreviewRequest(
				for: request,
				networkID: networkID,
				transactionManifest: manifestToSign,
				transactionSigners: transactionSigners
			)
			let transactionPreviewResponse = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
			guard transactionPreviewResponse.receipt.status == .succeeded else {
				throw TransactionFailure.fromFailedTXReviewResponse(transactionPreviewResponse)
			}
			let receiptBytes = try Data(hex: transactionPreviewResponse.encodedReceipt)

			/// Analyze the manifest
			let analyzedManifestToReview = try manifestToSign.executionSummary(networkId: networkID.rawValue, encodedReceipt: receiptBytes)

			/// Transactions created outside of the Wallet are not allowed to use reserved instructions
			if !request.isWalletTransaction, !analyzedManifestToReview.reservedInstructions.isEmpty {
				throw TransactionFailure.failedToPrepareTXReview(.manifestWithReservedInstructions(analyzedManifestToReview.reservedInstructions))
			}

			/// Get all of the expected signing factors.
			let signingFactors = try await {
				if let nonEmpty = NonEmpty<Set<EntityPotentiallyVirtual>>(transactionSigners.intentSignerEntitiesOrEmpty()) {
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
				executionSummary: analyzedManifestToReview,
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
				transactionManifest: manifestToSign,
				analyzedManifestToReview: analyzedManifestToReview,
				networkID: networkID,
				transactionFee: transactionFee,
				transactionSigners: transactionSigners,
				signingFactors: signingFactors
			)
		}

		@Sendable
		func createTransactionPreviewRequest(
			for request: ManifestReviewRequest,
			networkID: NetworkID,
			transactionManifest: TransactionManifest,
			transactionSigners: TransactionSigners
		) async throws -> GatewayAPI.TransactionPreviewRequest {
			let intent = try await buildTransactionIntent(.init(
				networkID: networkID,
				manifest: transactionManifest,
				message: request.message,
				nonce: request.nonce,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				transactionSigners: transactionSigners
			))

			return try .init(
				rawManifest: transactionManifest,
				header: intent.header(),
				transactionSigners: transactionSigners
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
	public static func feePayerSelectionAmongstCandidates(
		request: DetermineFeePayerRequest,
		allFeePayerCandidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>,
		involvedEntities: MyEntitiesInvolvedInTransaction
	) async throws -> FeePayerSelectionResult? {
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let totalCost = request.transactionFee.totalFee.max
		let allSignerEntities = request.transactionSigners.intentSignerEntitiesOrEmpty()

		func findFeePayer(
			amongst keyPath: KeyPath<MyEntitiesInvolvedInTransaction, OrderedSet<Profile.Network.Account>>,
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
	static func fromFailedTXReviewResponse(_ response: GatewayAPI.TransactionPreviewResponse) -> Self {
		let message = response.receipt.errorMessage ?? "Unknown reason"

		// Quite rudimentary, but it is not worth making something smarter,
		// as the GW will provide in the future strongly typed errors
		let isFailureDueToDepositRules = message.contains("AccountError(DepositIsDisallowed") ||
			message.contains("AccountError(NotAllBucketsCouldBeDeposited")

		if isFailureDueToDepositRules {
			return .failedToPrepareTXReview(.oneOfRecevingAccountsDoesNotAllowDeposits)
		} else {
			return .failedToPrepareTXReview(.failedToRetrieveTXReceipt(message))
		}
	}
}
