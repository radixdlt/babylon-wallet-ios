import ComposableArchitecture
import SwiftUI

extension SignWithFactorSourcesOfKindLedger.State {
	var viewState: SignWithFactorSourcesOfKindLedger.ViewState {
		.init(currentSigningFactor: currentSigningFactor)
	}
}

// MARK: - SignWithFactorSourcesOfKindLedger.View

extension SignWithFactorSourcesOfKindLedger {
	public struct ViewState: Equatable {
		let currentSigningFactor: SigningFactor?

		var ledger: LedgerHardwareWalletFactorSource? {
			currentSigningFactor.flatMap { $0.factorSource.extract() }
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSourcesOfKindLedger>

		public init(store: StoreOf<SignWithFactorSourcesOfKindLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			FactorSourceAccess.View(store: store.factorSourceAccess)
		}
	}
}

private extension StoreOf<SignWithFactorSourcesOfKindLedger> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
