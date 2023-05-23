import FeaturePrelude
import Profile

extension DerivePublicKeys.State {
	var viewState: DerivePublicKeys.ViewState {
		.init(ledger: ledgerBeingUsed, purpose: {
			switch purpose {
			case .createAuthSigningKey:
				return .createAuthSigningKey
			case .importLegacyAccounts:
				return .importLegacyAccounts
			case .createEntity:
				return .createAccount
			}
		}())
	}
}

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	public struct ViewState: Equatable {
		public let ledger: LedgerFactorSource?
		public let purpose: UseLedgerView.Purpose
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
						UseLedgerView(ledgerFactorSource: ledger, purpose: viewStore.purpose)
					} else {
						Color.white
					}
				}
				.onFirstTask { @MainActor in
					viewStore.send(.onFirstTask)
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
