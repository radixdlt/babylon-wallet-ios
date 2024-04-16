import ComposableArchitecture

// MARK: - SignWithFactorSource
public struct SignWithFactorSource: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		public let kind: Kind
		public let signingFactors: NonEmpty<Set<SigningFactor>>
		public let signingPurposeWithPayload: SigningPurposeWithPayload
		public var currentSigningFactor: SigningFactor?
		public var factorSourceAccess: FactorSourceAccess.State

		public init(
			kind: Kind,
			signingFactors: NonEmpty<Set<SigningFactor>>,
			signingPurposeWithPayload: SigningPurposeWithPayload
		) {
			self.kind = kind
			self.signingFactors = signingFactors
			self.signingPurposeWithPayload = signingPurposeWithPayload
			switch kind {
			case .device:
				assert(signingFactors.allSatisfy { $0.factorSource.kind == DeviceFactorSource.kind })
				self.factorSourceAccess = .init(kind: .device, purpose: .signature)
			case .ledger:
				assert(signingFactors.allSatisfy { $0.factorSource.kind == LedgerHardwareWalletFactorSource.kind })
				self.factorSourceAccess = .init(kind: .ledger(nil), purpose: .signature)
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<SignatureOfEntity>)
		case failedToSign(SigningFactor)
		case cancel
	}

	@CasePathable
	public enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: /Action.child .. ChildAction.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			signWithSigningFactors(of: state)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancel))
		default:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .signingWithFactor(factor):
			state.currentSigningFactor = factor
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
					allSignatures.append(contentsOf: signatures)
				} catch {
					await send(.delegate(.failedToSign(signingFactor)))
					break
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
		let dataToSign: Data = switch state.signingPurposeWithPayload {
		case let .signAuth(auth):
			auth.payloadToHashAndSign.hash().data
		case let .signTransaction(_, intent, _):
			intent.hash().hash.data
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
		}
	}
}

// MARK: - SignWithFactorSource.State.Kind
extension SignWithFactorSource.State {
	public enum Kind: Sendable, Hashable {
		case device
		case ledger
	}
}
