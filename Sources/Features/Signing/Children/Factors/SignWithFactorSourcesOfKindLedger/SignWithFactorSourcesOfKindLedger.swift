import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient

// MARK: - SignWithFactorSourcesOfKindLedger
public struct SignWithFactorSourcesOfKindLedger: SignWithFactorSourcesOfKindReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorSourcesOfKindState<Self>

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindActionProtocol {
		case done(signingFactors: NonEmpty<OrderedSet<SigningFactor>>, signatures: Set<AccountSignature>)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
//			return .run { [signingFactors = state.signingFactors, data = state.dataToSign] send in
//				let signatures = try await ledgerHardwareWalletClient.sign(
//					ledger: signingFactor.factorSource,
//					signers: Set(signingFactor.signers.map(\.account)),
//					unhashedDataToSign: data
//				)
//				await send(.delegate(.done(signingFactor: signingFactor, signatures: signatures)))
//			} catch: { _, _ in
//				loggerGlobal.error("Failed to device sign")
//			}
			return .none
		}
	}
}
