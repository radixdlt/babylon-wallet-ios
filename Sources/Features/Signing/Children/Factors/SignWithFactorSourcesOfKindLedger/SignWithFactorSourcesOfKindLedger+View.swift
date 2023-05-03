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
		VStack {
			Text("Signing with ledger").textStyle(.body1HighImportance)

			let factorSource = signingFactor.factorSource
			let ledger = P2P.LedgerHardwareWallet.LedgerDevice(factorSource: factorSource)
			let maybeName: String? = ledger.name?.rawValue
			let nameOrEmpty = maybeName.map { "'\($0)'" } ?? ""
			let display = "\(ledger.model.rawValue) - \(nameOrEmpty)"
			VPair(heading: "Ledger", item: display)
			VPair(heading: "Last used", item: factorSource.lastUsedOn.ISO8601Format())
			VPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
		}.padding()
	}
}
