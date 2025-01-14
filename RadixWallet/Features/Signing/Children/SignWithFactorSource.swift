import ComposableArchitecture

// MARK: - SignWithFactorSource
struct SignWithFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: Kind
		let signingFactors: NonEmpty<Set<SigningFactor>>
		let signingPurposeWithPayload: SigningPurposeWithPayload
		var factorSourceAccess: FactorSourceAccess.State

		init(
			kind: Kind,
			signingFactors: NonEmpty<Set<SigningFactor>>,
			signingPurposeWithPayload: SigningPurposeWithPayload
		) {
			self.kind = kind
			self.signingFactors = signingFactors
			self.signingPurposeWithPayload = signingPurposeWithPayload

			let purpose = signingPurposeWithPayload.factorSourceAccessPurpose
			switch kind {
			case .device:
				assert(signingFactors.allSatisfy { $0.factorSource.kind == DeviceFactorSource.kind })
				self.factorSourceAccess = .init(kind: .device, purpose: purpose)
			case .ledger:
				assert(signingFactors.allSatisfy { $0.factorSource.kind == LedgerHardwareWalletFactorSource.kind })
				let ledger: LedgerHardwareWalletFactorSource? = signingFactors.first?.factorSource.extract()
				self.factorSourceAccess = .init(kind: .ledger(ledger), purpose: purpose)
			}
		}
	}

	enum InternalAction: Sendable, Equatable {
		case signingWithFactor(SigningFactor)
	}

	enum DelegateAction: Sendable, Equatable {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<SignatureOfEntity>)
		case failedToSign(SigningFactor)
		case cancel
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			signWithSigningFactors(of: state)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancel))
		default:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .signingWithFactor(factor):
			switch state.kind {
			case .device:
				break
			case .ledger:
				let ledger: LedgerHardwareWalletFactorSource? = factor.factorSource.extract()
				state.factorSourceAccess = .init(kind: .ledger(ledger), purpose: .signature)
			}
			return .none
		}
	}

	private func signWithSigningFactors(of state: State) -> Effect<Action> {
		.run { [signingFactors = state.signingFactors] send in
			var allSignatures = Set<SignatureOfEntity>()
			for signingFactor in signingFactors {
				await send(.internal(.signingWithFactor(signingFactor)))

				do {
					let signatures = switch state.kind {
					case .device:
						try await sign(signers: signingFactor.signers, factor: signingFactor.factorSource.extract(as: DeviceFactorSource.self), state: state)
					case .ledger:
						try await sign(signers: signingFactor.signers, factor: signingFactor.factorSource.extract(as: LedgerHardwareWalletFactorSource.self), state: state)
					}
					allSignatures.formUnion(signatures)
				} catch let error as P2P.ConnectorExtension.Response.LedgerHardwareWallet.Failure where error.code == .userRejectedSigningOfTransaction {
					// If user rejected transaction on ledger device, we will inform the delegate to dismiss the signing sheet.
					await send(.delegate(.failedToSign(signingFactor)))
					return
				} catch {
					// In any other type of error, we will just allow them to retry.
					return
				}
			}
			await send(.delegate(.done(signingFactors: signingFactors, signatures: allSignatures)))
		}
	}

	private func sign(
		signers: SigningFactor.Signers,
		factor deviceFactorSource: DeviceFactorSource,
		state: State
	) async throws -> Set<SignatureOfEntity> {
		let dataToSign: Hash = switch state.signingPurposeWithPayload {
		case let .signAuth(auth):
			auth.payloadToHashAndSign.hash()
		case let .signTransaction(_, intent, _):
			intent.hash().hash
		case let .signPreAuthorization(intent):
			intent.hash().hash
		}

		return try await deviceFactorSourceClient.signUsingDeviceFactorSource(
			deviceFactorSource: deviceFactorSource,
			signerEntities: Set(signers.map(\.entity)),
			hashedDataToSign: dataToSign,
			purpose: .signTransaction(.manifestFromDapp)
		)
	}

	private func sign(
		signers: SigningFactor.Signers,
		factor ledger: LedgerHardwareWalletFactorSource,
		state: State
	) async throws -> Set<SignatureOfEntity> {
		switch state.signingPurposeWithPayload {
		case let .signTransaction(_, intent, _):
			try await ledgerHardwareWalletClient.signTransaction(.init(
				ledger: ledger,
				signers: signers,
				transactionIntent: intent,
				displayHashOnLedgerDisplay: false
			))

		case let .signAuth(authToSign):
			try await ledgerHardwareWalletClient.signAuthChallenge(.init(
				ledger: ledger,
				signers: signers,
				challenge: authToSign.input.challenge,
				origin: authToSign.input.origin,
				dAppDefinitionAddress: authToSign.input.dAppDefinitionAddress
			))

		case let .signPreAuthorization(subintent):
			try await ledgerHardwareWalletClient.signPreAuthorization(.init(
				ledger: ledger,
				signers: signers,
				subintent: subintent,
				displayHashOnLedgerDisplay: false
			))
		}
	}
}

// MARK: - SignWithFactorSource.State.Kind
extension SignWithFactorSource.State {
	enum Kind: Sendable, Hashable {
		case device
		case ledger
	}
}

private extension SigningPurposeWithPayload {
	var factorSourceAccessPurpose: FactorSourceAccess.State.Purpose {
		switch self {
		case .signAuth:
			.proveOwnership
		case .signTransaction, .signPreAuthorization:
			.signature
		}
	}
}
