import ClientPrelude
import Cryptography
import EngineToolkitClient
import EngineToolkitModels
import FactorSourcesClient
import GatewayAPI
import GatewaysClient
import SubmitTransactionClient
import TransactionClient
import UseFactorSourceClient

let minimumNumberOfEpochsPassedForFaucetToBeReused = 1
// internal for tests
let epochForWhenLastUsedByAccountAddressKey = "faucet.epochForWhenLastUsedByAccountAddressKey"

// MARK: - FaucetClient + DependencyKey
extension FaucetClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.engineToolkitClient) var engineToolkitClient

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

		/// This function can ONLY sign transaction which does not spend funds or otherwise require
		/// auth, since we use an ephemeral key pair
		@Sendable func signSubmitTX(manifest: TransactionManifest) async throws {
			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.secureStorageClient) var secureStorageClient
			@Dependency(\.useFactorSourceClient) var useFactorSourceClient
			@Dependency(\.factorSourcesClient) var factorSourcesClient
			@Dependency(\.submitTXClient) var submitTXClient

			let networkID = await gatewaysClient.getCurrentNetworkID()

			let ephemeralNotary = Curve25519.Signing.PrivateKey()

			let builtTransactionIntentWithSigners = try await transactionClient.buildTransactionIntent(
				.init(
					networkID: networkID,
					manifest: manifest,
					selectNotary: { _ in
						.init(notary: .ephemeralPublicKey(.eddsaEd25519(ephemeralNotary.publicKey)), notaryAsSignatory: true)
					}
				)
			)

			let transactionIntent = builtTransactionIntentWithSigners.intent
			let compiledTransactionIntent = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			let txID = try engineToolkitClient.generateTXID(transactionIntent)

			let notaryAndSigners = builtTransactionIntentWithSigners.notaryAndSigners

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: []
			)

			let compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)

			let hashToSign = try blake2b(data: compiledSignedIntent.compiledIntent)
			let notarySignatureRaw = try ephemeralNotary.signature(for: hashToSign)
			let notarySignature = Engine.Signature.eddsaEd25519(.init(bytes: Array(notarySignatureRaw)))

			let uncompiledNotarized = NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature
			)
			let compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)

			func debugPrintTX() {
				// RET prints when convertManifest is called, when it is removed, this can be moved down
				// inline inside `print`.
				let txIntentString = transactionIntent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
				print("\n\n🔮 DEBUG TRANSACTION START 🔮")
				print("TXID: \(txID.rawValue)")
				print("TransactionIntent: \(txIntentString)")
				print("intentSignatures: \(signedTransactionIntent.intentSignatures.map(\.signature.hex).joined(separator: "\n"))")
				print("NotarySignature: \(notarySignatureRaw.hex)")
				print("Compiled Transaction Intent:\n\n\(compiledTransactionIntent.compiledIntent.hex)\n\n")
				print("Compiled Notarized Intent:\n\n\(compiledNotarizedTXIntent.compiledIntent.hex)\n\n")
				print("🔮 DEBUG TRANSACTION END 🔮\n\n")
			}

//			debugPrintTX()

			_ = try await submitTXClient.submitTransaction(.init(txID: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent))

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
			let manifest = try engineToolkitClient.manifestForFaucet(
				includeLockFeeInstruction: true,
				networkID: networkID,
				accountAddress: accountAddress
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
			let manifest = try {
				if request.numberOfTokens == 1 {
					return try engineToolkitClient.manifestForCreateFungibleToken(
						networkID: networkID,
						accountAddress: request.recipientAccountAddress,
						tokenName: request.name,
						tokenSymbol: request.symbol
					)
				} else {
					return try engineToolkitClient.manifestForMultipleCreateFungibleToken(
						networkID: networkID,
						accountAddress: request.recipientAccountAddress,
						tokensCount: request.numberOfTokens
					)
				}
			}()

			try await signSubmitTX(manifest: manifest)
		}

		let createNonFungibleToken: CreateNonFungibleToken = { request in
			let networkID = await gatewaysClient.getCurrentNetworkID()
			let manifest = try {
				if request.numberOfTokens == 1 {
					return try engineToolkitClient.manifestForCreateNonFungibleToken(
						networkID: networkID,
						accountAddress: request.recipientAccountAddress,
						nftName: request.name
					)
				} else {
					return try engineToolkitClient.manifestForCreateMultipleNonFungibleToken(
						networkID: networkID,
						accountAddress: request.recipientAccountAddress,
						tokensCount: request.numberOfTokens,
						idsCount: request.numberOfIds
					)
				}
			}()

			try await signSubmitTX(manifest: manifest)
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

private extension UserDefaultsClient {
	func loadEpochForWhenLastUsedByAccountAddress() -> EpochForWhenLastUsedByAccountAddress {
		@Dependency(\.jsonDecoder) var jsonDecoder
		if
			let data = self.dataForKey(epochForWhenLastUsedByAccountAddressKey),
			let epochs = try? jsonDecoder().decode(EpochForWhenLastUsedByAccountAddress.self, from: data)
		{
			return epochs
		} else {
			return .init()
		}
	}

	func saveEpochForWhenLastUsedByAccountAddress(_ value: EpochForWhenLastUsedByAccountAddress) async {
		@Dependency(\.jsonEncoder) var jsonEncoder
		do {
			let data = try jsonEncoder().encode(value)
			await self.setData(data, epochForWhenLastUsedByAccountAddressKey)
		} catch {
			// Not important enough to throw...
		}
	}
}

// MARK: - EpochForWhenLastUsedByAccountAddress
// internal for tests
internal struct EpochForWhenLastUsedByAccountAddress: Codable, Hashable, Sendable {
	struct EpochForAccount: Codable, Sendable, Hashable, Identifiable {
		typealias ID = AccountAddress
		var id: ID { accountAddress }
		let accountAddress: AccountAddress
		var epoch: Epoch
	}

	internal var epochForAccounts: IdentifiedArrayOf<EpochForAccount>
	internal init(epochForAccounts: IdentifiedArrayOf<EpochForAccount> = .init()) {
		self.epochForAccounts = epochForAccounts
	}

	mutating func update(epoch: Epoch, for id: AccountAddress) {
		if var existing = epochForAccounts[id: id] {
			existing.epoch = epoch
			epochForAccounts[id: id] = existing
		} else {
			epochForAccounts.append(.init(accountAddress: id, epoch: epoch))
		}
	}

	func getEpoch(for accountAddress: AccountAddress) -> Epoch? {
		epochForAccounts[id: accountAddress]?.epoch
	}
}
