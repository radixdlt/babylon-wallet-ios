import AddLedgerFactorSourceFeature
import FeaturePrelude

// MARK: - CreationOfEntity.View
extension CreationOfEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
		let useLedgerAsFactorSource: Bool
		let ledgers: IdentifiedArrayOf<FactorSource>
		var ledgersArray: [FactorSource]? { .init(ledgers) }
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		struct SelectedLedgerControlRequirements: Hashable {
			let selectedLedger: FactorSource
		}

		init(state: CreationOfEntity.State) {
//			self.kind = Entity.entityKind
//			self.useLedgerAsFactorSource = state.useLedgerAsFactorSource
//			self.ledgers = state.ledgers
//			self.selectedLedgerID = state.selectedLedgerID
//			if let id = state.selectedLedgerID, let selectedLedger = state.ledgers[id: id] {
//				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
//			} else {
//				self.selectedLedgerControlRequirements = nil
//			}
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
			) { viewStore in
				Group {
					if viewStore.useLedgerAsFactorSource {
						createWithLedgerView(viewStore)
					} else {
						createWithDevice()
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
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
