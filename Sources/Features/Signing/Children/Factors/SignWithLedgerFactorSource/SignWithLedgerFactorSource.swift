import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithLedgerFactorSource
public struct SignWithLedgerFactorSource: SignWithFactorReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorState<Self>
	//    public struct State: SignWithFactorReducerStateProtocol {
	//        public let signingFactor: SigningFactor
	//        public let dataToSign: Data
	//        public init(signingFactor: SigningFactor, dataToSign: Data) {
	//            assert(signingFactor.factorSource.kind == .ledgerHQHardwareWallet)
	//            self.signingFactor = signingFactor
	//            self.dataToSign = dataToSign
	//        }
	//    }

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: SignWithFactorReducerActionProtocol {
		case done(signingFactor: SigningFactor, signatures: Set<AccountSignature>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
