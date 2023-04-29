import FactorSourcesClient
import FeaturePrelude

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

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
