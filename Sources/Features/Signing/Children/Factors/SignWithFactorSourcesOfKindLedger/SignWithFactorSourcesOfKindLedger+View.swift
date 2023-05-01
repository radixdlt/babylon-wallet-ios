import FactorSourcesClient
import FeaturePrelude

extension SignWithFactorSourcesOfKindLedger.State {
	var viewState: SignWithFactorSourcesOfKindLedger.ViewState {
		.init(currentSigningFactor: currentSigningFactor)
	}
}

// MARK: - SignWithFactorSourcesOfKindLedger.View
extension SignWithFactorSourcesOfKindLedger {
	public struct ViewState: Equatable {
		let currentSigningFactor: SigningFactor?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSourcesOfKindLedger>

		public init(store: StoreOf<SignWithFactorSourcesOfKindLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					if let currentSigningFactor = viewStore.currentSigningFactor {
						signing(with: currentSigningFactor)
					}
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

extension SignWithFactorSourcesOfKindLedger.View {
	@ViewBuilder
	private func signing(
		with signingFactor: SigningFactor
	) -> some SwiftUI.View {
		let ledger = P2P.LedgerHardwareWallet.LedgerDevice(factorSource: signingFactor.factorSource)
		let maybeName: String? = ledger.name?.rawValue
		let nameOrEmpty = maybeName.map { "'\($0)'" } ?? ""
		Text("Ledger \(ledger.model.rawValue) - \(nameOrEmpty)")
	}
}
