import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient

// MARK: - SignWithFactorSourcesOfKindLedger
public struct SignWithFactorSourcesOfKindLedger: SignWithFactorSourcesOfKindReducerProtocol {
	public typealias Factor = LedgerHardwareWalletFactorSource
	public typealias State = SignWithFactorSourcesOfKindState<Factor>

	public enum ViewAction: SignWithFactorSourcesOfKindViewActionProtocol {
		case onFirstTask
		case retryButtonTapped
	}

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<SignatureOfEntity>)
		case failedToSign(SigningFactor)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return signWithSigningFactors(of: state)

		case .retryButtonTapped:
			return signWithSigningFactors(of: state)
		}
	}

	public func reduce(
		into state: inout State,
		internalAction: InternalAction
	) -> EffectTask<Action> {
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
			let ledgerTXDisplayMode: LedgerHardwareWalletFactorSource.SigningDisplayMode = await appPreferencesClient.getPreferences().display.ledgerHQHardwareWalletSigningDisplayMode

			return try await ledgerHardwareWalletClient.signTransaction(.init(
				ledger: ledger,
				signers: signers,
				transactionIntent: intent,
				ledgerTXDisplayMode: ledgerTXDisplayMode.mode,
				displayHashOnLedgerDisplay: false
			))
		case let .signAuth(authToSign):
			return try await ledgerHardwareWalletClient.signAuthChallenge(.init(
				ledger: ledger,
				signers: signers,
				challenge: authToSign.input.challenge,
				origin: authToSign.input.origin,
				dAppDefinitionAddress: authToSign.input.dAppDefinitionAddress
			))
		}
	}
}

extension LedgerHardwareWalletFactorSource.SigningDisplayMode {
	// seperation so that we do not accidentally break profile or RadixConnect
	var mode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode {
		switch self {
		case .verbose: return .verbose
		case .summary: return .summary
		}
	}
}
