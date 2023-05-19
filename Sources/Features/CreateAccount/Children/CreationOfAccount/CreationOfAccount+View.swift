import AddLedgerFactorSourceFeature
import FeaturePrelude

extension CreationOfAccount {
	public struct ViewState: Equatable {
		let useLedgerAsFactorSource: Bool

		init(state: CreationOfAccount.State) {
			useLedgerAsFactorSource = false
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfAccount>

		public init(store: StoreOf<CreationOfAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: CreationOfAccount.ViewState.init(state:),
				send: { .view($0) }
			) { _ in
//				Group {
//					if viewStore.useLedgerAsFactorSource {
				//                        Text("Creating with Ledger...")
//
//					} else {
				//                        Text("Remove this text, which is to say: creating with .device")
//					}
//				}
				.onFirstTask { @MainActor in
					ViewStore(store.stateless).send(.view(.onFirstTask))
				}
			}
		}
	}
}

extension CreationOfAccount.ViewState {
	var navigationTitle: String {
		L10n.CreateEntity.Ledger.createAccount
	}
}
