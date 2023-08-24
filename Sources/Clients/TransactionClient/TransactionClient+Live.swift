import AccountPortfoliosClient
import AccountsClient
import ClientPrelude
import Cryptography
import EngineKit
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
				allAccounts.first { $0.address == accountAddress }
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Profile.Network.Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ extract: () -> [EngineToolkit.Address]) throws -> OrderedSet<Profile.Network.Account> {
				try .init(validating: extract().asSpecific().compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ extract: () -> [EngineToolkit.Address]) async throws -> OrderedSet<Profile.Network.Persona> {
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
		func getTransactionSigners(_ request: GetTransactionSignersRequest) async throws -> TransactionSigners {
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
		func feePayerSelectionAmongstCandidates(
			_ manifest: TransactionManifest,
			transactionFee: TransactionFee
		) async throws -> FeePayerSelectionAmongstCandidates {
			let lockFee = transactionFee.totalFee.lockFee

			let networkID = await gatewaysClient.getCurrentNetworkID()
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkID)
			let allFeePayerCandidates = try await accountPortfoliosClient.fetchAccountPortfolios(allAccounts.map(\.address), true).compactMap { portfolio -> FeePayerCandidate? in
				guard
					let account = allAccounts.first(where: { account in account.address == portfolio.owner })
				else {
					assertionFailure("Failed to find account or no balance, this should never happen.")
					return nil
				}
				return FeePayerCandidate(
					account: account,
					xrdBalance: portfolio.fungibleResources.xrdResource?.amount ?? .zero
				)
			}

			guard
				let allCandidates = NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>(rawValue: .init(uncheckedUniqueElements: allFeePayerCandidates))
			else {
				struct NoFeePayerCandidates: Error {}
				// Should not ever happen, user should have at least one account
				throw NoFeePayerCandidates()
			}

			let feePayer: FeePayerCandidate? = try? await {
				guard lockFee > .zero else {
					return nil
				}

				let myInvolvedEntities = try await myEntitiesInvolvedInTransaction(
					networkID: networkID,
					manifest: manifest
				)

				let candidatesWithEnoughFunds = allFeePayerCandidates.filter {
					$0.xrdBalance >= lockFee
				}

				func findFeePayer(
					amongst keyPath: KeyPath<MyEntitiesInvolvedInTransaction, OrderedSet<Profile.Network.Account>>
				) async throws -> FeePayerCandidate? {
					let accountsToCheck = myInvolvedEntities[keyPath: keyPath]
					return candidatesWithEnoughFunds.first { accountsToCheck.contains($0.account) }
				}

				// First try amonst `accountsWithdrawnFrom`
				if let feePayer = try await findFeePayer(amongst: \.accountsWithdrawnFrom) {
					loggerGlobal.debug("Find suitable fee payer in: 'accountsWithdrawnFrom', specifically: \(feePayer)")
					return feePayer
				}
				// no candiates amonst `accountsWithdrawnFrom` => fallback to `accountsRequiringAuth`
				if let feePayer = try await findFeePayer(amongst: \.accountsRequiringAuth) {
					loggerGlobal.debug("Find suitable fee payer in: 'accountsRequiringAuth', specifically: \(feePayer)")
					return feePayer
				}
				// no candiates amonst `accountsRequiringAuth` => fallback to `accountsDepositedInto`
				if let feePayer = try await findFeePayer(amongst: \.accountsDepositedInto) {
					loggerGlobal.debug("Find suitable fee payer in: 'accountsDepositedInto', specifically: \(feePayer)")
					return feePayer
				}
				loggerGlobal.debug("Did not find any suitable fee payer, retrieving candidates for user selection....")
				return nil
			}()

			return .init(selected: feePayer, candidates: allCandidates, transactionFee: transactionFee)
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

			return .init(
				intent: .init(header: header, manifest: request.manifest, message: request.message),
				transactionSigners: request.transactionSigners
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
				txID: txID
			)
		}

		let getTransactionReview: GetTransactionReview = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()

			/// Get all transaction signers.
			let transactionSigners = try await getTransactionSigners(.init(
				networkID: networkID,
				manifest: request.manifestToSign,
				ephemeralNotaryPublicKey: request.ephemeralNotaryPublicKey
			))

			/// Get all of the expected signing factors.
			let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
				networkID: networkID,
				signers: .init(rawValue: Set(transactionSigners.intentSignerEntitiesOrEmpty()))!,
				signingPurpose: .signTransaction(.manifestFromDapp)
			))

			/// Get the transaction preview
			let transactionPreviewRequest = try await createTransactionPreviewRequest(for: request, networkID: networkID, transactionSigners: transactionSigners)
			let transactionPreviewResponse = try await gatewayAPIClient.transactionPreview(transactionPreviewRequest)
			guard transactionPreviewResponse.receipt.status == .succeeded else {
				throw TransactionFailure.failedToPrepareTXReview(
					.failedToRetrieveTXReceipt(transactionPreviewResponse.receipt.errorMessage ?? "Unknown reason")
				)
			}
			let receiptBytes = try [UInt8](hex: transactionPreviewResponse.encodedReceipt)

			/// Analyze the manifest
			let analyzedManifestToReview = try request.manifestToSign.analyzeExecution(transactionReceipt: receiptBytes)

			/// Calculate the expecte transaction fee
			let transactionFee = try TransactionFee(executionAnalysis: analyzedManifestToReview, signaturesCount: signingFactors.expectedSignatureCount)

			/// Select the account that can pay the transaction fee
			let feePayerSelection = try await feePayerSelectionAmongstCandidates(request.manifestToSign, transactionFee: transactionFee)

			return TransactionToReview(
				analyzedManifestToReview: analyzedManifestToReview,
				networkID: networkID,
				feePayerSelectionAmongstCandidates: feePayerSelection,
				transactionSigners: transactionSigners,
				signingFactors: signingFactors
			)
		}

		@Sendable
		func createTransactionPreviewRequest(
			for request: ManifestReviewRequest,
			networkID: NetworkID,
			transactionSigners: TransactionSigners
		) async throws -> GatewayAPI.TransactionPreviewRequest {
			let intent = try await buildTransactionIntent(.init(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: request.manifestToSign,
				message: request.message,
				nonce: request.nonce,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput,
				transactionSigners: transactionSigners
			))

			return try .init(
				rawManifest: request.manifestToSign,
				header: intent.intent.header(),
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

		return Self(
			getTransactionReview: getTransactionReview,
			buildTransactionIntent: buildTransactionIntent,
			notarizeTransaction: notarizeTransaction,
			myInvolvedEntities: myInvolvedEntities
		)
	}
}
