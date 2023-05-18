import AddLedgerFactorSourceFeature
import FeaturePrelude

// MARK: - CreationOfEntity.View
extension CreationOfEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
		let useLedgerAsFactorSource: Bool

		init(state: CreationOfEntity.State) {
			self.kind = Entity.entityKind
			fatalError()
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfEntity>

		public init(store: StoreOf<CreationOfEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: CreationOfEntity.ViewState.init(state:),
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

extension CreationOfEntity.View {
	private func createWithDevice() -> some SwiftUI.View {
		Color.white
	}
}

extension CreationOfEntity.ViewState {
	var navigationTitle: String {
		switch kind {
		case .account:
			return L10n.CreateEntity.Ledger.createAccount
		case .identity:
			return L10n.CreateEntity.Ledger.createPersona
		}
	}
}
