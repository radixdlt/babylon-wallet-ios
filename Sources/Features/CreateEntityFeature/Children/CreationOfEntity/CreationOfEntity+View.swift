import AddLedgerFactorSourceFeature
import FeaturePrelude

// MARK: - CreationOfEntity.View
extension CreationOfEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
		let entityKindName: String
		let useLedgerAsFactorSource: Bool
		let ledgers: IdentifiedArrayOf<FactorSource>
		let selectedLedgerID: FactorSourceID
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		struct SelectedLedgerControlRequirements: Hashable {
			let selectedLedger: FactorSource
		}

		init(state: CreationOfEntity.State) {
			let entityKind = Entity.entityKind
			self.kind = entityKind

			let entityKindName = entityKind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKindName = entityKindName

			self.useLedgerAsFactorSource = state.useLedgerAsFactorSource
			self.ledgers = state.ledgers
			self.selectedLedgerID = state.selectedLedgerID
			if let selectedLedger = state.ledgers[id: state.selectedLedgerID] {
				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
			} else {
				self.selectedLedgerControlRequirements = nil
			}
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
	private func createWithLedgerView(_ viewStore: ViewStoreOf<CreationOfEntity>) -> some SwiftUI.View {
		VStack {
			if viewStore.ledgers.isEmpty {
				Text("You have no Ledgers added, add a ledger to get started...")
			} else {
				Text("Select Ledger to Use")
				Picker(
					"Ledger Device",
					selection: viewStore.binding(
						get: \.selectedLedgerID,
						send: { .selectedLedger(id: $0) }
					)
				) {
					ForEach(viewStore.ledgers, id: \.self) { ledger in
						Text("Ledger \(ledger.description.rawValue) | \(ledger.label.rawValue) (added: \(ledger.addedOn.ISO8601Format())")
							.tag(ledger.id)
					}
				}
			}

			Spacer()

			Button("Add new ledger") {
				viewStore.send(.addNewLedgerButtonTapped)
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: true))
		}
		.padding(.horizontal, .small1)
		.navigationTitle("Create Ledger \(viewStore.entityKindName)")
		.footer {
			WithControlRequirements(
				viewStore.selectedLedgerControlRequirements,
				forAction: { viewStore.send(.confirmedLedger($0.selectedLedger)) }
			) { action in
				Button("Use Ledger", action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
		.sheet(
			store: store.scope(
				state: \.$addNewLedger,
				action: { .child(.addNewLedger($0)) }
			),
			content: { AddLedgerFactorSource.View(store: $0) }
		)
	}

	private func createWithDevice() -> some SwiftUI.View {
		Color.white
	}
}

//// MARK: - LedgerView
// struct LedgerView: SwiftUI.View {
//    let ledger: FactorSource
//    var body: some View {
//        VStack {
//            Text(ledger.label.rawValue)
//            Text(ledger.description.rawValue)
//            Text("Added: \(ledger.addedOn.ISO8601Format())")
//            Text("Last used on: \(ledger.lastUsedOn.ISO8601Format())")
//        }
//    }
// }
