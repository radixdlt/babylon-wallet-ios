import FeaturePrelude
import Profile

extension DerivePublicKeys.State {
	var viewState: DerivePublicKeys.ViewState {
		.init(ledger: ledgerBeingUsed)
	}
}

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	public struct ViewState: Equatable {
		public let ledger: LedgerHardwareWalletFactorSource?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DerivePublicKeys>

		public init(store: StoreOf<DerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Group {
					if let ledger = viewStore.ledger {
						Text(ledger.hint.name)
							.border(.green)
					} else {
						Color.white
					}
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.navigationTitle(L10n.CreateEntity.Ledger.createAccount)
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DerivePublicKey_Preview
// struct DerivePublicKey_Preview: PreviewProvider {
//	static var previews: some View {
//		DerivePublicKeys.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DerivePublicKeys()
//			)
//		)
//	}
// }
//
// extension DerivePublicKeys.State {
//	public static let previewValue = Self()
// }
// #endif
