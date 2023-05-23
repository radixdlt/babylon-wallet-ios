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
		let mode: ChooseLedgerHardwareDevice.State.Mode
		let ledgers: Loadable<IdentifiedArrayOf<LedgerFactorSource>>
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		let navigationTitle: String
		let subtitle: String
		let showFooter: Bool

		init(state: ChooseLedgerHardwareDevice.State) {
			self.mode = state.mode
			self.ledgers = state.$ledgers
			self.selectedLedgerID = state.selectedLedgerID
			if let id = state.selectedLedgerID, let selectedLedger = state.ledgers?[id: id] {
				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
			} else {
				self.selectedLedgerControlRequirements = nil
			}

			switch mode {
			case .select:
				self.navigationTitle = L10n.CreateEntity.Ledger.createAccount
				self.subtitle = L10n.CreateEntity.Ledger.subtitleSelectLedger
				self.showFooter = true
			case .list:
				self.navigationTitle = "Ledger Hardware Wallets" // FIXME: Strings
				self.subtitle = "Here are all the Ledger devices you have connected to" // FIXME: Strings
				self.showFooter = false
			}
		}

		var ledgersArray: [LedgerFactorSource]? { .init(ledgers.wrappedValue ?? []) }
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
						Text(viewStore.subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Link)
							.flushedLeft

						Button("What is a Ledger Factor Source") { // FIXME: Strings
							viewStore.send(.whatIsALedgerButtonTapped)
						}
						.buttonStyle(.info)
						.flushedLeft

						ledgerList(viewStore: viewStore)

						Button(L10n.CreateEntity.Ledger.addNewLedger) {
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
				.footer(visible: viewStore.showFooter) {
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

		@ViewBuilder
		private func ledgerList(viewStore: ViewStoreOf<ChooseLedgerHardwareDevice>) -> some SwiftUI.View {
			switch viewStore.ledgers {
			case .idle, .loading, .failure:
				EmptyView()
			case let .success(ledgers):
				if ledgers.isEmpty {
					Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)
				} else {
					switch viewStore.mode {
					case .list:
						ForEach(ledgers) { ledger in
							LedgerRowView(viewState: .init(factorSource: ledger))
						}
					case .select:
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
