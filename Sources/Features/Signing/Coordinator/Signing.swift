import Cryptography
import CustomDump
import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude
import Profile
import TransactionClient

// MARK: - K1.PublicKey + CustomDumpStringConvertible
extension K1.PublicKey: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		self.compressedRepresentation.hex
	}
}

// MARK: - CompileTransactionIntentResponse + CustomDumpStringConvertible
extension CompileTransactionIntentResponse: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		compiledIntent.hex
	}
}

// MARK: - CompileNotarizedTransactionIntentResponse + CustomDumpStringConvertible
extension CompileNotarizedTransactionIntentResponse: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		compiledIntent.hex
	}
}

// MARK: - Curve25519.Signing.PublicKey + CustomDumpStringConvertible
extension Curve25519.Signing.PublicKey: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		rawRepresentation.hex
	}
}

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case prepare(PrepareForSigning.State)
			case signWithDeviceFactors(SignWithFactorSourcesOfKindDevice.State)
			case signWithLedgerFactors(SignWithFactorSourcesOfKindLedger.State)
		}

		public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates

		public var step: Step

		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public var factorsLeftToSignWith: SigningFactors = [:]
		public var expectedSignatureCount = -1
		public var signatures: OrderedSet<Signature> = []
		public let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey

		public init(
			networkID: NetworkID,
			manifest: TransactionManifest,
			feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
		) {
			let ephemeralNotaryPrivateKey = Curve25519.Signing.PrivateKey()
			self.step = .prepare(.init(
				manifest: manifest,
				networkID: networkID,
				feePayer: feePayerSelectionAmongstCandidates.selected.account,
				ephemeralNotaryPublicKey: ephemeralNotaryPrivateKey.publicKey
			))
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
			self.feePayerSelectionAmongstCandidates = feePayerSelectionAmongstCandidates
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case finishedSigningWithAllFactors
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
	}

	public enum ChildAction: Sendable, Equatable {
		case prepare(PrepareForSigning.Action)
		case signWithDeviceFactors(SignWithFactorSourcesOfKindDevice.Action)
		case signWithLedgerFactors(SignWithFactorSourcesOfKindLedger.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case notarized(NotarizeTransactionResponse)
		case failedToSign
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.transactionClient) var transactionClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.prepare,
				action: /Action.child .. ChildAction.prepare
			) {
				PrepareForSigning()
			}
			Scope(
				state: /State.Step.signWithDeviceFactors,
				action: /Action.child .. ChildAction.signWithDeviceFactors
			) {
				SignWithFactorSourcesOfKindDevice()
			}
			Scope(
				state: /State.Step.signWithLedgerFactors,
				action: /Action.child .. ChildAction.signWithLedgerFactors
			) {
				SignWithFactorSourcesOfKindLedger()
			}
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .finishedSigningWithAllFactors:
			guard let compiledIntent = state.compiledIntent else {
				assertionFailure("Expected compiledIntent")
				return .none
			}
			let notaryKey: SLIP10.PrivateKey = .curve25519(state.ephemeralNotaryPrivateKey)

			return .run { [signatures = state.signatures] send in
				await send(.internal(.notarizeResult(TaskResult {
					let intentSignatures: Set<Engine.SignatureWithPublicKey> = try Set(signatures.map {
						try $0.signatureWithPublicKey.intoEngine()
					})
					return try await transactionClient.notarizeTransaction(.init(
						intentSignatures: intentSignatures,
						compileTransactionIntent: compiledIntent,
						notary: notaryKey
					))
				})))
			}
		case let .notarizeResult(.failure(error)):
			loggerGlobal.error("Failed to notarize transaction, error: \(error)")
			errorQueue.schedule(error)
			return .none
		case let .notarizeResult(.success(notarized)):
			return .send(.delegate(.notarized(notarized)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .prepare(.delegate(.failedToBuildTX)):
			return .none
		case .prepare(.delegate(.failedToLoadSigners)):
			return .none
		case let .prepare(.delegate(.done(compiledIntent, signingFactors))):
			state.compiledIntent = compiledIntent
			state.factorsLeftToSignWith = signingFactors
			state.expectedSignatureCount = signingFactors.signerCount
			func printSigners() {
				for (factorSourceKind, signingFactorsOfKind) in signingFactors {
					print("🔮 ~~~ SIGNINGFACTORS OF KIND: \(factorSourceKind) #\(signingFactorsOfKind.count) many: ~~~")
					for signingFactor in signingFactorsOfKind {
						let factorSource = signingFactor.factorSource
						print("\t🔮 == Signers for factorSource: \(factorSource.label) \(factorSource.description): ==")
						for signer in signingFactor.signers {
							let account = signer.account
							print("\t\t🔮 * Account: \(account.displayName) \(account.address): *")
							for factorInstance in signer.factorInstancesRequiredToSign {
								print("\t\t\t🔮 * FactorInstance: \(String(describing: factorInstance.derivationPath)) \(factorInstance.publicKey)")
							}
						}
					}
				}
			}
//			printSigners()
			return proceedWithNextFactorSource(&state)

		case
			let .signWithDeviceFactors(.delegate(.done(factors, signatures))),
			let .signWithLedgerFactors(.delegate(.done(factors, signatures))):
			return handleSignatures(signingFactors: factors, signatures: signatures, &state)
		default:
			return .none
		}
	}

	private func handleSignatures(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signatures: Set<AccountSignature>,
		_ state: inout State
	) -> EffectTask<Action> {
		state.signatures.append(contentsOf: signatures.map(\.signature))
		let kind = signingFactors.first.factorSource.kind
		precondition(signingFactors.allSatisfy { $0.factorSource.kind == kind })
		state.factorsLeftToSignWith.removeValue(forKey: kind)
		return .fireAndForget {
			try? await factorSourcesClient.updateLastUsed(.init(
				factorSourceIDs: signingFactors.map(\.factorSource.id),
				usagePurpose: .transactionSigning
			))
		}.concatenate(with: proceedWithNextFactorSource(&state))
	}

	private func proceedWithNextFactorSource(_ state: inout State) -> EffectTask<Action> {
		guard let intent = state.compiledIntent else {
			assertionFailure("expected intent")
			return .none
		}
		if
			let nextKind = state.factorsLeftToSignWith.keys.first,
			let nextFactors = state.factorsLeftToSignWith[nextKind]
		{
			let dataToSign = Data(intent.compiledIntent)
			switch nextKind {
			case .device:
				state.step = .signWithDeviceFactors(.init(signingFactors: nextFactors, dataToSign: dataToSign))
			case .ledgerHQHardwareWallet:
				state.step = .signWithLedgerFactors(.init(signingFactors: nextFactors, dataToSign: dataToSign))
			}
			return .none
		} else {
			assert(state.signatures.count == state.expectedSignatureCount)
			return .send(.internal(.finishedSigningWithAllFactors))
		}
	}
}
