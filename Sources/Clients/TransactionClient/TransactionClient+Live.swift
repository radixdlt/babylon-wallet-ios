import AccountPortfoliosClient
import AccountsClient
import ClientPrelude
import Cryptography
import FactorSourcesClient
import GatewayAPI
import GatewaysClient
import PersonasClient
import Resources

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
}

extension TransactionClient {
	public static var liveValue: Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable
		func myEntitiesInvolvedInTransaction(
			networkID: NetworkID,
			manifest: TransactionManifest
		) async throws -> MyEntitiesInvolvedInTransaction {
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)

			func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Profile.Network.Account? {
				allAccounts.first(where: { $0.address == accountAddress })
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Profile.Network.Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ extract: @escaping () -> [EngineToolkit.Address]) throws -> OrderedSet<Profile.Network.Account> {
				try .init(validating: extract().asSpecific().compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ extract: @escaping () -> [EngineToolkit.Address]) async throws -> OrderedSet<Profile.Network.Persona> {
				try await .init(validating: extract().asSpecific().asyncMap(identityFromComponentAddress))
			}

			return try await MyEntitiesInvolvedInTransaction(
				identitiesRequiringAuth: mapIdentity(manifest.identitiesRequiringAuth),
				accountsRequiringAuth: mapAccount(manifest.accountsRequiringAuth),
				accountsWithdrawnFrom: mapAccount(manifest.accountsWithdrawnFrom),
				accountsDepositedInto: mapAccount(manifest.accountsDepositedInto)
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
					return .notaryIsSignatory
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

		let lockFeeWithSelectedPayer: LockFeeWithSelectedPayer = { manifest, feeToAdd, addressOfPayer in
			// assert account still has enough funds to pay
			guard await accountsWithEnoughFunds(from: [addressOfPayer], toPay: feeToAdd).first?.owner == addressOfPayer else {
				assertionFailure("did you JUST spend funds? unlucky...")
				throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
			}

			loggerGlobal.debug("Setting fee payer to: \(addressOfPayer.address)")
			return try manifest.withLockFeeCallMethodAdded(address: addressOfPayer.asGeneral())
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

			let header = TransactionHeader(
				networkId: request.networkID.rawValue,
				startEpochInclusive: epoch.rawValue,
				endEpochExclusive: (epoch + request.makeTransactionHeaderInput.epochWindow).rawValue,
				nonce: request.nonce.rawValue,
				notaryPublicKey: SLIP10.PublicKey.eddsaEd25519(transactionSigners.notaryPublicKey).intoEngine(),
				notaryIsSignatory: transactionSigners.notaryIsSignatory,
				tipPercentage: request.makeTransactionHeaderInput.tipPercentage
			)

			return .init(
				intent: .init(header: header, manifest: request.manifest),
				transactionSigners: transactionSigners
			)
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
				txID: .init(txID.asStr())
			)
		}

		let getTransactionReview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			let transactionPreviewRequest = try await createTransactionPreviewRequest(for: request, networkID: networkID)
			let transactionPreviewResponse = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
			guard transactionPreviewResponse.receipt.status == .succeeded else {
				throw TransactionFailure.failedToPrepareTXReview(
					.failedToRetrieveTXReceipt(transactionPreviewResponse.receipt.errorMessage ?? "Unknown reason")
				)
			}
			let receiptBytes = try [UInt8](hex: transactionPreviewResponse.encodedReceipt)

			let analyzedManifestToReview = try request.manifestToSign.analyzeExecution(transactionReceipt: receiptBytes)

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
				nonce: request.nonce,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			return try .init(
				rawManifest: request.manifestToSign,
				header: intent.intent.header(),
				transactionSigners: intent.transactionSigners
			)
		}

		let prepareForSigning: PrepareForSigning = { request in
			let transactionIntentWithSigners = try await buildTransactionIntent(.init(
				networkID: request.networkID,
				manifest: request.manifest,
				nonce: request.nonce,
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			let entities = NonEmpty(
				rawValue: Set(Array(transactionIntentWithSigners.transactionSigners.intentSignerEntitiesOrEmpty()) + [.account(request.feePayer)])
			)!

			let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
				networkID: request.networkID,
				signers: entities,
				signingPurpose: request.purpose
			))

			func printSigners() {
				for (factorSourceKind, signingFactorsOfKind) in signingFactors {
					print("🔮 ~~~ SIGNINGFACTORS OF KIND: \(factorSourceKind) #\(signingFactorsOfKind.count) many: ~~~")
					for signingFactor in signingFactorsOfKind {
						let factorSource = signingFactor.factorSource
						print("\t🔮 == Signers for factorSource: \(factorSource.id): ==")
						for signer in signingFactor.signers {
							let entity = signer.entity
							print("\t\t🔮 * Entity: \(entity.displayName): *")
							for factorInstance in signer.factorInstancesRequiredToSign {
								print("\t\t\t🔮 * FactorInstance: \(String(describing: factorInstance.derivationPath)) \(factorInstance.publicKey)")
							}
						}
					}
				}
			}
			printSigners()

			return .init(intent: transactionIntentWithSigners.intent, signingFactors: signingFactors)
		}

		let myInvolvedEntities: MyInvolvedEntities = { manifest in
			let networkID = await gatewaysClient.getCurrentNetworkID()
			return try await myEntitiesInvolvedInTransaction(
				networkID: networkID,
				manifest: manifest
			)
		}

		return Self(
			lockFeeBySearchingForSuitablePayer: lockFeeBySearchingForSuitablePayer,
			lockFeeWithSelectedPayer: lockFeeWithSelectedPayer,
			getTransactionReview: getTransactionReview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction,
			prepareForSigning: prepareForSigning,
			myInvolvedEntities: myInvolvedEntities
		)
	}
}
