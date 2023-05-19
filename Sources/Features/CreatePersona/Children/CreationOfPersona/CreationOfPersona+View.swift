import DerivePublicKeyFeature
import FeaturePrelude

extension CreationOfPersona {
	public struct ViewState: Equatable {
		init(state: CreationOfPersona.State) {}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfPersona>

		public init(store: StoreOf<CreationOfPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: CreationOfPersona.ViewState.init(state:),
				send: { .view($0) }
			) { _ in

				DerivePublicKey.View(
					store: store.scope(
						state: \.derivePublicKey,
						action: { CreationOfPersona.Action.child(.derivePublicKey($0)) }
					)
				)
//				Group {
//					if viewStore.useLedgerAsFactorSource {
//						createWithLedgerView(viewStore)
//					} else {
//						createWithDevice()
//					}
//				}
				Text("Hmm add Ledger selection her if able..")
//				.onAppear {
//					viewStore.send(.appeared)
//				}
			}
		}
	}
}

extension CreationOfPersona.View {
	private func createWithDevice() -> some SwiftUI.View {
		Color.white
	}
}

extension CreationOfPersona.ViewState {
	var navigationTitle: String {
		L10n.CreateEntity.Ledger.createPersona
	}
}
