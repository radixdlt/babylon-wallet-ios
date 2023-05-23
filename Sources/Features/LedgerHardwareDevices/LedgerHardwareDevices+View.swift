import AddLedgerFactorSourceFeature
import FeaturePrelude
import Profile

extension LedgerHardwareDevices.State {
	var viewState: LedgerHardwareDevices.ViewState {
		.init(state: self)
	}
}

// MARK: - LedgerHardwareDevice.View
extension LedgerHardwareDevices {
	public struct ViewState: Equatable {
		let allowSelection: Bool
		let showHeaders: Bool
		let ledgers: Loadable<IdentifiedArrayOf<LedgerFactorSource>>
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		let navigationTitle: String
		let subtitle: String

		init(state: LedgerHardwareDevices.State) {
			self.allowSelection = state.allowSelection
			self.showHeaders = state.showHeaders
			self.ledgers = state.$ledgers
			self.selectedLedgerID = state.selectedLedgerID
			if let id = state.selectedLedgerID, let selectedLedger = state.ledgers?[id: id] {
				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
			} else {
				self.selectedLedgerControlRequirements = nil
			}

			if allowSelection {
				self.navigationTitle = "Choose Ledger Device" // FIXME: Strings
				self.subtitle = "Choose a Ledger hardware wallet device" // FIXME: Strings -> L10n.CreateEntity.Ledger.subtitleSelectLedger
			} else {
				self.navigationTitle = "Ledger Hardware Wallets" // FIXME: Strings
				self.subtitle = "Here are all the Ledger devices you have connected to" // FIXME: Strings
			}
		}

		var ledgersArray: [LedgerFactorSource]? { .init(ledgers.wrappedValue ?? []) }
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<LedgerHardwareDevices>

		public init(store: StoreOf<LedgerHardwareDevices>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium3) {
						if viewStore.showHeaders {
							Text(viewStore.subtitle)
								.foregroundColor(.app.gray2)
								.textStyle(.body1Link)
								.flushedLeft

							Button("What is a Ledger Factor Source") { // FIXME: Strings
								viewStore.send(.whatIsALedgerButtonTapped)
							}
							.buttonStyle(.info)
							.flushedLeft
						}

						ledgerList(viewStore: viewStore)

						Button("Add Ledger Device") { // FIXME: Strings -> L10n.CreateEntity.Ledger.addNewLedger
							viewStore.send(.addNewLedgerButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
						.padding(.top, .small1)

						Spacer(minLength: 0)
					}
					.padding(.horizontal, .medium1)
					.padding(.top, .small1)
				}
				.navigationTitle(viewStore.navigationTitle)
				.footer(visible: viewStore.allowSelection) {
					WithControlRequirements(
						viewStore.selectedLedgerControlRequirements,
						forAction: { viewStore.send(.confirmedLedger($0.selectedLedger)) }
					) { action in
						// FIXME: Strings: remove L10n.CreateEntity.Ledger.useLedger
						Button(L10n.Common.continue, action: action)
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

		@ViewBuilder
		private func ledgerList(viewStore: ViewStoreOf<LedgerHardwareDevices>) -> some SwiftUI.View {
			switch viewStore.ledgers {
			case .idle, .loading, .failure:
				EmptyView()
			case let .success(ledgers):
				if ledgers.isEmpty {
					Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)
				} else if viewStore.allowSelection {
					Selection(
						viewStore.binding(
							get: \.ledgersArray,
							send: { .selectedLedger(id: $0?.first?.id) }
						),
						from: ledgers,
						requiring: .exactly(1)
					) { item in
						LedgerRowView(
							viewState: .init(factorSource: item.value),
							isSelected: item.isSelected,
							action: item.action
						)
					}
				} else {
					ForEach(ledgers) { ledger in
						LedgerRowView(viewState: .init(factorSource: ledger))
					}
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
