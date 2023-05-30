import AddLedgerFactorSourceFeature
import FeaturePrelude
import NewConnectionFeature
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
		let ledgers: Loadable<IdentifiedArrayOf<LedgerHardwareWalletFactorSource>>
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

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
		}

		var ledgersArray: [LedgerHardwareWalletFactorSource]? { .init(ledgers.wrappedValue ?? []) }

		var navigationTitle: String {
			if allowSelection {
				return "Choose Ledger Device" // FIXME: Strings
			} else {
				return "Ledger Hardware Wallets" // FIXME: Strings
			}
		}

		var subtitle: String? {
			switch ledgers {
			case .idle, .loading:
				return nil
			case .failure:
				return "Could not load ledger devices"
			case .success([]):
				return L10n.CreateEntity.Ledger.subtitleNoLedgers
			case .success:
				if allowSelection {
					return "Choose a Ledger hardware wallet device" // FIXME: Strings -> L10n.CreateEntity.Ledger.subtitleSelectLedger
				} else {
					return "Here are all the Ledger devices you have connected to" // FIXME: Strings
				}
			}
		}
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
							if let subtitle = viewStore.subtitle {
								Text(subtitle)
									.foregroundColor(.app.gray2)
									.textStyle(.body1Link)
									.flushedLeft
							}

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
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private func ledgerList(viewStore: ViewStoreOf<LedgerHardwareDevices>) -> some SwiftUI.View {
			switch viewStore.ledgers {
			case .idle, .loading, .failure,
			     // We are already showing `subtitleNoLedgers` in the header
			     .success([]) where viewStore.showHeaders:
				EmptyView()
			case .success([]):
				Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)
					.flushedLeft
			case let .success(ledgers):
				if viewStore.allowSelection {
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

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<LedgerHardwareDevices>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return addNewLedgerSheet(with: destinationStore)
			.addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
	}

	@MainActor
	private func addNewLedgerSheet(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destinations.State.addNewLedger,
			action: LedgerHardwareDevices.Destinations.Action.addNewLedger,
			content: { AddLedgerFactorSource.View(store: $0) }
		)
	}

	@MainActor
	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destinations.State.addNewP2PLink,
			action: LedgerHardwareDevices.Destinations.Action.addNewP2PLink,
			content: { NewConnection.View(store: $0) }
		)
	}

	@MainActor
	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destinations.State.noP2PLink,
			action: LedgerHardwareDevices.Destinations.Action.noP2PLink
		)
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
