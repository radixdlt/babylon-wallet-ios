import Cryptography
import FeaturePrelude

// MARK: - DerivePublicKey
public struct DerivePublicKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let derivationPath: DerivationPath

		/// Mutable so that we can add more ledgers in case of `ledgers`
		public var factorSourceOption: FactorSourceOption
		public enum FactorSourceOption: Sendable, Hashable {
			case ledgers(IdentifiedArrayOf<FactorSource>)
			case ledger(FactorSource)
			case device(BabylonDeviceFactorSource)
		}

		public init(
			derivationPath: DerivationPath,
			factorSourceOption: FactorSourceOption
		) {
			self.derivationPath = derivationPath
			self.factorSourceOption = factorSourceOption
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction {
		case derivedPublicKey(
			SLIP10.PublicKey,
			derivationPath: DerivationPath
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
