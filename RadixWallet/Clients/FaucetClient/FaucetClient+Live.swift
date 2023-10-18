
let minimumNumberOfEpochsPassedForFaucetToBeReused = 1

// MARK: - FaucetClient + DependencyKey
extension FaucetClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.gatewaysClient) var gatewaysClient

		// Return `nil` for `not allowed to use` else: return `some` for `is alllowed to use`
		@Sendable func isAllowedToUseFaucetIfSoGetEpochs(accountAddress: AccountAddress) async -> (epochs: EpochForWhenLastUsedByAccountAddress, current: Epoch?)? {
			@Dependency(\.gatewayAPIClient.getEpoch) var getEpoch
			let epochs = userDefaultsClient.loadEpochForWhenLastUsedByAccountAddress()
			guard let current = try? await getEpoch() else { return (epochs, nil) /* is allowed to use */ }
			guard let last = epochs.getEpoch(for: accountAddress) else { return (epochs, current) /* is allowed to use */ }

			// Edge case
			if current < last {
				// a network reset has happened (for betanet/testnet) => allow
				return (epochs, current) /* is allowed to use */
			}

			// will never be negative thx to `if current < last` check above.
			let delta = current - last

			guard delta.rawValue >= minimumNumberOfEpochsPassedForFaucetToBeReused else {
				return nil /* NOT allowed to use */
			}
			return (epochs, current) /* is allowed to use */
		}

		let isAllowedToUseFaucet: IsAllowedToUseFaucet = { accountAddress in
			await isAllowedToUseFaucetIfSoGetEpochs(accountAddress: accountAddress) != nil
		}

		@Sendable func signSubmitTX(
			manifest: TransactionManifest
		) async throws {
			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.submitTXClient) var submitTXClient

			let networkID = await gatewaysClient.getCurrentNetworkID()

			let ephemeralNotary = Curve25519.Signing.PrivateKey()

			let transactionIntent = try await transactionClient.buildTransactionIntent(
				.init(
					networkID: networkID,
					manifest: manifest,
					message: .none,
					makeTransactionHeaderInput: .default,
					transactionSigners: .init(notaryPublicKey: ephemeralNotary.publicKey, intentSigning: .notaryIsSignatory)
				)
			)

			let notarized = try await transactionClient.notarizeTransaction(.init(
				intentSignatures: [],
				transactionIntent: transactionIntent,
				notary: .curve25519(ephemeralNotary)
			))

			let txID = notarized.txID

			_ = try await submitTXClient.submitTransaction(.init(
				txID: txID,
				compiledNotarizedTXIntent: notarized.notarized
			))

			try await submitTXClient.hasTXBeenCommittedSuccessfully(txID)
		}

		let getFreeXRD: GetFreeXRD = { faucetRequest in

			let accountAddress = faucetRequest.recipientAccountAddress
			guard let epochsAndMaybeCurrent = await isAllowedToUseFaucetIfSoGetEpochs(
				accountAddress: accountAddress
			) else {
				assertionFailure("UI allowed faucet to be used, but we were in fact not allowed to use it.")
				return
			}

			let networkID = await gatewaysClient.getCurrentNetworkID()
			let manifest = try ManifestBuilder.manifestForFaucet(
				includeLockFeeInstruction: true,
				networkID: networkID,
				componentAddress: accountAddress.asGeneral
			)

			try await signSubmitTX(manifest: manifest)

			// Try update last used
			guard let current = epochsAndMaybeCurrent.current else {
				// we failed to get current, so we cannot set the last used.
				return
			}
			// Update last used
			var epochs = epochsAndMaybeCurrent.epochs
			epochs.update(epoch: current, for: accountAddress)
			await userDefaultsClient.saveEpochForWhenLastUsedByAccountAddress(epochs)

			// Done
		}

		#if DEBUG
		let createFungibleToken: CreateFungibleToken = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()
			// TODO: Re-enable. With new manifest builder that is not easy to handle.
			let manifest = if request.numberOfTokens == 1 {
				try ManifestBuilder.manifestForCreateFungibleToken(
					account: request.recipientAccountAddress,
					networkID: networkID
				)
			} else {
				try ManifestBuilder.manifestForCreateMultipleFungibleTokens(
					account: request.recipientAccountAddress,
					networkID: networkID
				)
			}

			try await signSubmitTX(manifest: manifest)
		}

		let createNonFungibleToken: CreateNonFungibleToken = { _ in
			fatalError()
			// TODO: Re-enable. With new manifest builder that is not easy to handle.
//			let networkID = await gatewaysClient.getCurrentNetworkID()
//			let manifest = try {
//				if request.numberOfTokens == 1 {
//					return try TransactionManifest.manifestForCreateNonFungibleToken(
//						account: request.recipientAccountAddress,
//						network: networkID
//					)
//				} else {
//					return try TransactionManifest.manifestForCreateMultipleNonFungibleTokens(
//						account: request.recipientAccountAddress,
//						network: networkID
//					)
//				}
//			}()

//			try await signSubmitTX(manifest: manifest)
		}

		return Self(
			getFreeXRD: getFreeXRD,
			isAllowedToUseFaucet: isAllowedToUseFaucet,
			createFungibleToken: createFungibleToken,
			createNonFungibleToken: createNonFungibleToken
		)
		#else
		return Self(
			getFreeXRD: getFreeXRD,
			isAllowedToUseFaucet: isAllowedToUseFaucet
		)
		#endif // DEBUG
	}()
}
