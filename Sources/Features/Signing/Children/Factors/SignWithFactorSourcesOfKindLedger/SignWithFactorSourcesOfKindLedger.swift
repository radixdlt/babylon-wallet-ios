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
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<AccountSignature>)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [signingFactors = state.signingFactors, data = state.dataToSign] send in
				var allSignatures = Set<AccountSignature>()
				for signingFactor in signingFactors {
					let signatures = try await ledgerHardwareWalletClient.sign(
						signingFactor: signingFactor,
						unhashedDataToSign: data
					)
					allSignatures.append(contentsOf: signatures)
				}
				await send(.delegate(.done(signingFactors: signingFactors, signatures: allSignatures)))
			} catch: { _, _ in
				loggerGlobal.error("Failed to device sign")
			}
		}
	}
}
