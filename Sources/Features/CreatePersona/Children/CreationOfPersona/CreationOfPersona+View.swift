import AddLedgerFactorSourceFeature
import FeaturePrelude

extension CreationOfPersona {
	public struct ViewState: Equatable {
		init(state: CreationOfPersona.State) {
			fatalError()
		}
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
