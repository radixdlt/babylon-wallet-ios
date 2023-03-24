import AccountPortfolioFetcherClient
import AccountsClient
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

		let pollStrategy: PollStrategy = .default

		@Sendable
		func compileAndSign(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> Result<(txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse), TransactionFailure.CompileOrSignFailure> {
			let compiledTransactionIntent: CompileTransactionIntentResponse
			do {
				compiledTransactionIntent = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			} catch {
				loggerGlobal.error("Failed to compile TX intent: \(error)")
				return .failure(.failedToCompileTXIntent)
			}

			let txID: TXID
			do {
				txID = try engineToolkitClient.generateTXID(transactionIntent)
			} catch {
				loggerGlobal.error("Failed to generate TX ID: \(error)")
				return .failure(.failedToGenerateTXId)
			}

			// Enables us to only read from keychain once per mnemonic
			let cachedPrivateHDFactorSources = ActorIsolated<IdentifiedArrayOf<PrivateHDFactorSource>>([])

			@Sendable func sign(
				unhashed unhashed_: some DataProtocol,
				with account: Profile.Network.Account,
				debugOrigin origin: String
			) async throws -> SignatureWithPublicKey {
				switch account.securityState {
				case let .unsecured(unsecuredControl):
					let factorInstance = unsecuredControl.genesisFactorInstance
					let factorSources = try await factorSourcesClient.getFactorSources()

					let privateHDFactorSource: PrivateHDFactorSource = try await { @Sendable () async throws -> PrivateHDFactorSource in

						let cache = await cachedPrivateHDFactorSources.value
						if let cached = cache[id: factorInstance.factorSourceID] {
							return cached
						}

						guard
							let factorSource = factorSources[id: factorInstance.factorSourceID],
							let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorInstance.factorSourceID, .signTransaction)
						else {
							throw TransactionFailure.failedToCompileOrSign(.failedToLoadFactorSourceForSigning)
						}

						let privateHDFactorSource = try PrivateHDFactorSource(
							mnemonicWithPassphrase: loadedMnemonicWithPassphrase,
							hdOnDeviceFactorSource: .init(factorSource: factorSource)
						)

						await cachedPrivateHDFactorSources.setValue(cache.appending(privateHDFactorSource))

						return privateHDFactorSource
					}()

					let hdRoot = try privateHDFactorSource.mnemonicWithPassphrase.hdRoot()
					let curve = privateHDFactorSource.hdOnDeviceFactorSource.parameters.supportedCurves.last
					let unhashedData = Data(unhashed_)

					loggerGlobal.debug("🔏 Signing data, origin=\(origin), with account=\(account.displayName), curve=\(curve), factorSourceKind=\(privateHDFactorSource.hdOnDeviceFactorSource.kind), factorSourceHint=\(privateHDFactorSource.hdOnDeviceFactorSource.hint)")

					return try await useFactorSourceClient.signatureFromOnDeviceHD(.init(
						hdRoot: hdRoot,
						derivationPath: factorInstance.derivationPath!,
						curve: curve,
						unhashedData: unhashedData
					))
				}
			}

			let intentSignatures_: [SignatureWithPublicKey]
			do {
				intentSignatures_ = try await notaryAndSigners.accountsNeededToSign.asyncMap {
					try await sign(
						unhashed: compiledTransactionIntent.compiledIntent,
						with: $0,
						debugOrigin: "Intent Signers"
					)
				}
			} catch {
				loggerGlobal.error("Failed to sign intent with account signers: \(error)")
				return .failure(.failedToSignIntentWithAccountSigners)
			}

			let intentSignatures: [Engine.SignatureWithPublicKey]
			do {
				intentSignatures = try intentSignatures_.map { try $0.intoEngine() }
			} catch {
				loggerGlobal.error("Failed to convert account signatures: \(error)")
				return .failure(.failedToConvertAccountSignatures)
			}

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: intentSignatures
			)
			let compiledSignedIntent: CompileSignedTransactionIntentResponse
			do {
				compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)
			} catch {
				loggerGlobal.error("Failed to compile signed TX intent: \(error)")
				return .failure(.failedToCompileSignedTXIntent)
			}

			let notarySignatureWithPublicKey: SignatureWithPublicKey
			do {
				notarySignatureWithPublicKey = try await sign(
					unhashed: compiledSignedIntent.compiledIntent,
					with: notaryAndSigners.notarySigner,
					debugOrigin: "Notary signer"
				)
			} catch {
				loggerGlobal.error("Failed to sign compiled TX intent with notary signer: \(error)")
				return .failure(.failedToSignSignedCompiledIntentWithNotarySigner)
			}

			let notarySignature: Engine.Signature
			do {
				notarySignature = try notarySignatureWithPublicKey.intoEngine().signature
			} catch {
				loggerGlobal.error("Failed to convert notary signature: \(error)")
				return .failure(.failedToConvertNotarySignature)
			}
			let uncompiledNotarized = NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature
			)
			let compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
			do {
				compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)
			} catch {
				loggerGlobal.error("Failed to compile notarized tx intent: \(error)")
				return .failure(.failedToCompileNotarizedTXIntent)
			}

			func debugPrintTX() {
				// RET prints when convertManifest is called, when it is removed, this can be moved down
				// inline inside `print`.
				let txIntentString = transactionIntent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
				print("\n\n🔮 DEBUG TRANSACTION START 🔮")
				print("TXID: \(txID.rawValue)")
				print("TransactionIntent: \(txIntentString)")
				print("intentSignatures: \(signedTransactionIntent.intentSignatures.map(\.signature.hex).joined(separator: "\n"))")
				do {
					try print("NotarySignature: \(notarySignatureWithPublicKey.signature.serialize().hex)")
				} catch {}
				print("Compiled Transaction Intent:\n\n\(compiledTransactionIntent.compiledIntent.hex)\n\n")
				print("Compiled Notarized Intent:\n\n\(compiledNotarizedTXIntent.compiledIntent.hex)\n\n")
				print("🔮 DEBUG TRANSACTION END 🔮\n\n")
			}

//			debugPrintTX()

			return .success((txID: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent))
		}

		@Sendable
		func submitNotarizedTX(
			id txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
		) async -> Result<TXID, SubmitTXFailure> {
			@Dependency(\.continuousClock) var clock;

			// MARK: Submit TX
			loggerGlobal.debug("About to submit notarized TX")

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: Data(compiledNotarizedTXIntent.compiledIntent).hex
			)

			let response: GatewayAPI.TransactionSubmitResponse

			do {
				response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
			} catch {
				loggerGlobal.error("Failed to submit TX to gateway, error: \(error)")
				return .failure(.failedToSubmitTX)
			}

			guard !response.duplicate else {
				loggerGlobal.error("Submitted TX was duplicate.")
				return .failure(.invalidTXWasDuplicate(txID: txID))
			}

			// MARK: Poll Status

			var txStatus: GatewayAPI.TransactionStatus = .pending

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHashHex: txID.rawValue
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse.status
			}

			var pollCount = 0

			loggerGlobal.debug("About to start polling")

			while !txStatus.isComplete {
				defer { pollCount += 1 }
				try? await clock.sleep(for: .seconds(pollStrategy.sleepDuration))

				do {
					txStatus = try await pollTransactionStatus()
					loggerGlobal.debug("Polled TX status is: \(txStatus)")
				} catch {
					loggerGlobal.error("Failed to poll TX status, error \(error)")
					// FIXME: - mainnet: improve handling of polling failure, should probably not return failure..
					return .failure(.failedToPollTX(txID: txID, error: .init(error: error)))
				}

				if pollCount >= pollStrategy.maxPollTries {
					loggerGlobal.error("Failed to poll TX, timed out after \(pollCount) attempts.")
					return .failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollCount)))
				}
			}
			guard txStatus == .committedSuccess else {
				loggerGlobal.error("TX finished but not `committedSuccess`, got: \(txStatus)")
				return .failure(.invalidTXWasSubmittedButNotSuccessful(txID: txID, status: txStatus == .rejected ? .rejected : .failed))
			}

			return .success(txID)
		}

		@Sendable
		func signAndSubmit(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> TransactionResult {
			await compileAndSign(transactionIntent: transactionIntent, notaryAndSigners: notaryAndSigners)
				.mapError { TransactionFailure.failedToCompileOrSign($0) }
				.asyncFlatMap { (txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse) in
					await submitNotarizedTX(id: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent).mapError {
						TransactionFailure.failedToSubmit($0)
					}
				}
		}

		@Sendable
		func buildTransactionIntent(
			networkID: NetworkID,
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> Result<(intent: TransactionIntent, notaryAndSigners: NotaryAndSigners), TransactionFailure.FailedToPrepareForTXSigning> {
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch: Epoch
			do {
				epoch = try await gatewayAPIClient.getEpoch()
			} catch {
				return .failure(.failedToGetEpoch)
			}

			let version = engineToolkitClient.getTransactionVersion()

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			let notaryAndSigners: NotaryAndSigners
			do {
				notaryAndSigners = try await getNotaryAndSigners(accountAddressesNeedingToSignTransactionRequest)
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

			return .success((intent, notaryAndSigners))
		}

		@Sendable
		func signAndSubmit(
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @escaping @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> TransactionResult {
			await buildTransactionIntent(
				networkID: gatewaysClient.getCurrentNetworkID(),
				manifest: manifest,
				makeTransactionHeaderInput: makeTransactionHeaderInput,
				getNotaryAndSigners: getNotaryAndSigners
			).mapError {
				TransactionFailure.failedToPrepareForTXSigning($0)
			}.asyncFlatMap { intent, notaryAndSigners in
				await signAndSubmit(transactionIntent: intent, notaryAndSigners: notaryAndSigners)
			}
		}

		let signAndSubmitTransaction: SignAndSubmitTransaction = { @Sendable request in
			await signAndSubmit(
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput
			) { accountAddressesNeedingToSignTransactionRequest in

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

				return .init(notarySigner: notary, accountsNeededToSign: accountsNeededToSign)
			}
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

		@Sendable
		func firstAccountAddressWithEnoughFunds(from addresses: [AccountAddress], toPay fee: BigDecimal, on networkID: NetworkID) async -> AccountAddress? {
			let xrdContainers = await addresses.concurrentMap {
				await accountPortfolioFetcherClient.fetchXRDBalance(of: $0, on: networkID)
			}.compactMap { $0 }
			return xrdContainers.first(where: { $0.amount >= fee })?.owner
		}

		return Self(
			convertManifestInstructionsToJSONIfItWasString: convertManifestInstructionsToJSONIfItWasString,
			addLockFeeInstructionToManifest: { maybeStringManifest in
				let manifestWithJSONInstructions: JSONInstructionsTransactionManifest
				do {
					manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
				} catch {
					loggerGlobal.error("Failed to convert manifest: \(String(describing: error))")
					throw TransactionFailure.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid)
				}

				var instructions = manifestWithJSONInstructions.instructions
				let networkID = await gatewaysClient.getCurrentNetworkID()

				let version = engineToolkitClient.getTransactionVersion()

				let accountsSuitableToPayForTXFeeRequest = AccountAddressesInvolvedInTransactionRequest(
					version: version,
					manifest: manifestWithJSONInstructions.convertedManifestThatContainsThem,
					networkID: networkID
				)

				let lockFeeAmount: BigDecimal = 10

				let accountAddress: AccountAddress = try await { () async throws -> AccountAddress in
					let accountAddressesSuitableToPayTransactionFeeRef =
						try engineToolkitClient.accountAddressesSuitableToPayTransactionFee(accountsSuitableToPayForTXFeeRequest)

					if let accountInvolvedInTransaction = await firstAccountAddressWithEnoughFunds(
						from: Array(accountAddressesSuitableToPayTransactionFeeRef),
						toPay: lockFeeAmount,
						on: networkID
					) {
						return accountInvolvedInTransaction
					} else {
						let allAccountAddresses = try await accountsClient.getAccountsOnCurrentNetwork().map(\.address)

						if let anyAccount = await firstAccountAddressWithEnoughFunds(
							from: allAccountAddresses.rawValue,
							toPay: lockFeeAmount,
							on: networkID
						) {
							return anyAccount
						} else {
							throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
						}
					}
				}()

				let lockFeeCallMethodInstruction = engineToolkitClient.lockFeeCallMethod(
					address: ComponentAddress(address: accountAddress.address),
					fee: lockFeeAmount.description
				).embed()

				instructions.insert(lockFeeCallMethodInstruction, at: 0)
				return TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
			},
			signAndSubmitTransaction: signAndSubmitTransaction
		)
	}
}

// MARK: - NotaryAndSigners
struct NotaryAndSigners: Sendable, Hashable {
	/// Notary signer
	public let notarySigner: Profile.Network.Account
	/// Never empty, since this also contains the notary signer.
	public let accountsNeededToSign: NonEmpty<OrderedSet<Profile.Network.Account>>
}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch self {
		case .committedSuccess, .committedFailure, .rejected:
			return true
		case .pending, .unknown:
			return false
		}
	}
}

// MARK: - PollStrategy
public struct PollStrategy {
	public let maxPollTries: Int
	public let sleepDuration: TimeInterval
	public init(maxPollTries: Int, sleepDuration: TimeInterval) {
		self.maxPollTries = maxPollTries
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(maxPollTries: 20, sleepDuration: 2)
}

// MARK: - GatewayAPI.TransactionCommittedDetailsResponse + Sendable
extension GatewayAPI.TransactionCommittedDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.TransactionStatus + Sendable
extension GatewayAPI.TransactionStatus: @unchecked Sendable {}

// MARK: - FailedToGetDetailsOfSuccessfullySubmittedTX
struct FailedToGetDetailsOfSuccessfullySubmittedTX: LocalizedError, Equatable {
	public let txID: TXID
	var errorDescription: String? {
		"Successfully submitted TX with txID: \(txID) but failed to get transaction details for it."
	}
}

// MARK: - SubmitTXFailure
// FIXME: - mainnet: improve handling of polling failure
/// This failure might be a false positive, due to i.e. POLLING of tx failed, but TX might have
/// been submitted successfully. Or we might have successfully submitted the TX but failed to get details about it.
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate(txID: TXID)

	/// Failed to poll, maybe TX was submitted successfully?
	case failedToPollTX(txID: TXID, error: FailedToPollError)

	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: TXFailureStatus)

	public var errorDescription: String? {
		switch self {
		case .failedToSubmitTX:
			return "Failed to submit transaction"
		case let .invalidTXWasDuplicate(txID):
			return "Duplicate TX id: \(txID)"
		case let .failedToPollTX(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .failedToGetTransactionStatus(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .invalidTXWasSubmittedButNotSuccessful(txID, status):
			return "Invalid TX submitted but not successful, status: \(status.localizedDescription) txID: \(txID)"
		}
	}
}

// MARK: - TXFailureStatus
public enum TXFailureStatus: String, LocalizedError, Sendable, Hashable {
	case rejected
	case failed
	public var errorDescription: String? {
		switch self {
		case .rejected: return "Rejected"
		case .failed: return "Failed"
		}
	}
}

// MARK: - FailedToPollError
public struct FailedToPollError: Sendable, LocalizedError, Equatable {
	public let error: Swift.Error
	public var errorDescription: String? {
		"Poll failed: \(String(describing: error))"
	}
}

// MARK: - FailedToGetTransactionStatus
public struct FailedToGetTransactionStatus: Sendable, LocalizedError, Equatable {
	public let pollAttempts: Int
	public var errorDescription: String? {
		"\(Self.self)(afterPollAttempts: \(String(describing: pollAttempts))"
	}
}

extension LocalizedError where Self: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}

extension IdentifiedArrayOf {
	func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
	}
}
