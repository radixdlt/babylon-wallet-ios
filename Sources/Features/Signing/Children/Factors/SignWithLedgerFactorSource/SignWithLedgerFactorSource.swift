import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient

// MARK: - SignWithLedgerFactorSource
public struct SignWithLedgerFactorSource: SignWithFactorReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorState<Self>

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: SignWithFactorReducerActionProtocol {
		case done(signingFactor: SigningFactor, signatures: Set<AccountSignature>)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [signingFactor = state.signingFactor, data = state.dataToSign] send in
				let signatures = try await ledgerHardwareWalletClient.sign(
					ledger: signingFactor.factorSource,
					signers: Set(signingFactor.signers.map(\.account)),
					unhashedDataToSign: data
				)
				await send(.delegate(.done(signingFactor: signingFactor, signatures: signatures)))
			} catch: { _, _ in
				loggerGlobal.error("Failed to device sign")
			}
		}
	}
}
