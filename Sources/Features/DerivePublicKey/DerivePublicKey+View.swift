import FeaturePrelude
import Profile

extension DerivePublicKey.State {
	var viewState: DerivePublicKey.ViewState {
		.init(ledger: ledgerBeingUsed, purpose: self.purpose == .createAuthSigningKey ? .createAuthSigningKey : .createAccount)
	}
}

// MARK: - DerivePublicKey.View
extension DerivePublicKey {
	public struct ViewState: Equatable {
		public let ledger: LedgerFactorSource?
		public let purpose: UseLedgerView.Purpose
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DerivePublicKey>

		public init(store: StoreOf<DerivePublicKey>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Group {
					if let ledger = viewStore.ledger {
						UseLedgerView(ledgerFactorSource: ledger, purpose: viewStore.purpose)
					} else {
						Color.white
					}
				}
				.onFirstTask { @MainActor in
					ViewStore(store.stateless).send(.view(.onFirstTask))
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DerivePublicKey_Preview
// struct DerivePublicKey_Preview: PreviewProvider {
//	static var previews: some View {
//		DerivePublicKey.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DerivePublicKey()
//			)
//		)
//	}
// }
//
// extension DerivePublicKey.State {
//	public static let previewValue = Self()
// }
// #endif
