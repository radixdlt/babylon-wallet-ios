import FactorSourcesClient
import FeaturePrelude

extension SignWithFactorSourcesOfKindLedger.State {
	var viewState: SignWithFactorSourcesOfKindLedger.ViewState {
		.init(currentSigningFactor: currentSigningFactor, purpose: self.signingPurposeWithPayload.purpose == .signAuth ? .signAuth : .signTX)
	}
}

// MARK: - SignWithFactorSourcesOfKindLedger.View
extension SignWithFactorSourcesOfKindLedger {
	public struct ViewState: Equatable {
		let currentSigningFactor: SigningFactor?
		let purpose: UseLedgerView.Purpose
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
					if
						let currentSigningFactor = viewStore.currentSigningFactor,
						let ledger = try? LedgerHardwareWalletFactorSource(factorSource: currentSigningFactor.factorSource)
					{
						UseLedgerView(
							ledgerFactorSource: ledger,
							purpose: viewStore.purpose
						)
					}
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
		}
	}
}
