import AddLedgerFactorSourceFeature
import FeaturePrelude

extension CreationOfAccount {
	public struct ViewState: Equatable {
		let useLedgerAsFactorSource: Bool

		init(state: CreationOfAccount.State) {
			fatalError()
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

extension CreationOfAccount.View {
	private func createWithDevice() -> some SwiftUI.View {
		Color.white
	}
}

extension CreationOfAccount.ViewState {
	var navigationTitle: String {
		L10n.CreateEntity.Ledger.createAccount
	}
}
