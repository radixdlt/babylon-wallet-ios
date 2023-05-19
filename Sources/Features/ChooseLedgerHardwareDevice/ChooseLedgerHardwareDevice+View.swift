import AddLedgerFactorSourceFeature
import FeaturePrelude
import Profile

extension ChooseLedgerHardwareDevice.State {
	var viewState: ChooseLedgerHardwareDevice.ViewState {
		.init(state: self)
	}
}

// MARK: - ChooseLedgerHardwareDevice.View
extension ChooseLedgerHardwareDevice {
	public struct ViewState: Equatable {
		let ledgers: IdentifiedArrayOf<LedgerFactorSource>
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		init(state: ChooseLedgerHardwareDevice.State) {
			self.ledgers = state.ledgers
			self.selectedLedgerID = state.selectedLedgerID
			if let id = state.selectedLedgerID, let selectedLedger = state.ledgers[id: id] {
				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
			} else {
				self.selectedLedgerControlRequirements = nil
			}
		}

		var ledgersArray: [LedgerFactorSource]? { .init(ledgers) }
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseLedgerHardwareDevice>

		public init(store: StoreOf<ChooseLedgerHardwareDevice>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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
				.onFirstTask { @MainActor in
					ViewStore(store.stateless).send(.view(.onFirstTask))
				}
			}
		}
	}
}

// MARK: - SelectLedgerRow
enum SelectLedgerRow {
	struct ViewState: Equatable {
		let description: String
		let addedOn: String
		let lastUsedOn: String

		init(factorSource: LedgerFactorSource) {
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - ChooseLedgerHardwareDevice_Preview
// struct ChooseLedgerHardwareDevice_Preview: PreviewProvider {
//	static var previews: some View {
//		ChooseLedgerHardwareDevice.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ChooseLedgerHardwareDevice()
//			)
//		)
//	}
// }
//
// extension ChooseLedgerHardwareDevice.State {
//	public static let previewValue = Self()
// }
// #endif
