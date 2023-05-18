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
	private func createWithLedgerView(_ viewStore: ViewStoreOf<CreationOfEntity>) -> some SwiftUI.View {
		VStack {
			if viewStore.ledgers.isEmpty {
				Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
			} else {
				Text(L10n.CreateEntity.Ledger.subtitleSelectLedger)

				ScrollView {
					VStack(spacing: .small1) {
						Selection(
							viewStore.binding(
								get: \.ledgersArray,
								send: { .selectedLedger(id: $0?.first?.id) }
							),
							from: viewStore.ledgers,
							requiring: .exactly(1)
						) { item in
							SelectLedgerRow.View(
								viewState: .init(factorSource: item.value),
								isSelected: item.isSelected,
								action: item.action
							)
						}
					}

					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
			}

			Spacer()

			Button(L10n.CreateEntity.Ledger.addNewLedger) {
				viewStore.send(.addNewLedgerButtonTapped)
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: true))
		}
		.padding(.horizontal, .small1)
		.navigationTitle(viewStore.navigationTitle)
		.footer {
			WithControlRequirements(
				viewStore.selectedLedgerControlRequirements,
				forAction: { viewStore.send(.confirmedLedger($0.selectedLedger)) }
			) { action in
				Button(L10n.CreateEntity.Ledger.useLedger, action: action)
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

// MARK: - SelectLedgerRow
enum SelectLedgerRow {
	struct ViewState: Equatable {
		let description: String
		let addedOn: String
		let lastUsedOn: String

		init(factorSource: FactorSource) {
			description = "\(factorSource.label.rawValue) (\(factorSource.description.rawValue))"
			addedOn = factorSource.addedOn.ISO8601Format(.iso8601Date(timeZone: .current))
			lastUsedOn = factorSource.lastUsedOn.ISO8601Format(.iso8601Date(timeZone: .current))
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack {
					VStack(alignment: .leading, spacing: 0) {
						Text(viewState.description)
							.textStyle(.body1Header)

						HPair(label: L10n.CreateEntity.Ledger.usedHeading, item: viewState.lastUsedOn)

						HPair(label: L10n.CreateEntity.Ledger.addedHeading, item: viewState.addedOn)
					}

					Spacer()

					RadioButton(
						appearance: .light,
						state: isSelected ? .selected : .unselected
					)
				}
				.foregroundColor(.app.white)
				.padding(.medium1)
				.background(.black)
				.brightness(isSelected ? -0.1 : 0)
				.cornerRadius(.small1)
			}
			.buttonStyle(.inert)
		}
	}
}
