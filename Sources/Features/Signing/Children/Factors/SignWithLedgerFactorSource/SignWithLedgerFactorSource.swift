import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithLedgerFactorSource
public struct SignWithLedgerFactorSource: SignWithFactorReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorState<Self>

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: SignWithFactorReducerActionProtocol {
		case done(signingFactors: NonEmpty<OrderedSet<SigningFactor>>, signatures: Set<AccountSignature>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
