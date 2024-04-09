import ComposableArchitecture
import SwiftUI

// MARK: - SignWithFactorSourcesOfKindLedger
public struct SignWithFactorSourcesOfKindLedger: SignWithFactorSourcesOfKindReducer {
	public typealias Factor = LedgerHardwareWalletFactorSource
	public typealias State = SignWithFactorSourcesOfKindState<Factor>

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<SignatureOfEntity>)
		case failedToSign(SigningFactor)
	}

	@CasePathable
	public enum ChildAction: SignWithFactorSourcesOfKindChildActionProtocol {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

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
		default:
			.none
		}
	}

	public func reduce(
		into state: inout State,
		internalAction: InternalAction
	) -> Effect<Action> {
		switch internalAction {
		case let .signingWithFactor(currentLedger):
			state.currentSigningFactor = currentLedger
			return .none
		}
	}

	public func sign(
		signers: SigningFactor.Signers,
		factor ledger: Factor,
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
