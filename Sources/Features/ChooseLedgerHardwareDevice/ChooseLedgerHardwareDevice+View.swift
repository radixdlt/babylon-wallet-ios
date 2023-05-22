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
				ScrollView {
					VStack(spacing: .medium3) {
						if viewStore.ledgers.isEmpty {
							Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
						} else {
							Text(L10n.CreateEntity.Ledger.subtitleSelectLedger)

							Selection(
								viewStore.binding(
									get: \.ledgersArray,
									send: { .selectedLedger(id: $0?.first?.id) }
								),
								from: viewStore.ledgers + viewStore.ledgers,
								requiring: .exactly(1)
							) { item in
								LedgerRowView(
									viewState: .init(factorSource: item.value),
									isSelected: item.isSelected,
									action: item.action
								)
								.padding(.horizontal, .large2)
							}
						}

						Button(L10n.CreateEntity.Ledger.addNewLedger) {
							viewStore.send(.addNewLedgerButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
						.padding(.top, .small1)

						Spacer(minLength: 0)
					}
					.padding(.top, .small1)
				}
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
					viewStore.send(.onFirstTask)
				}
			}
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
