import EngineToolkit
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient

// MARK: - SignWithFactorSourcesOfKindLedger
public struct SignWithFactorSourcesOfKindLedger: SignWithFactorSourcesOfKindReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorSourcesOfKindState<Self>

	public enum ViewAction: SignWithFactorSourcesOfKindViewActionProtocol {
		case appeared
	}

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<AccountSignature>)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
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

	public func sign(signingFactor: SigningFactor, state: State) async throws -> Set<AccountSignature> {
		do {
			let expectedHash = try blake2b(data: state.dataToSign)
			loggerGlobal.notice("\n\nExpected hash: \(expectedHash.hex)\n\n")
		} catch {
			loggerGlobal.critical("Failed to hash: \(error)")
		}
		return try await ledgerHardwareWalletClient.sign(.init(
			signingFactor: signingFactor,
			unhashedDataToSign: state.dataToSign
		))
	}
}
