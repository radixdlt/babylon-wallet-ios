import ComposableArchitecture
import SwiftUI
extension LedgerHardwareDevices.State {
	var viewState: LedgerHardwareDevices.ViewState {
		.init(state: self)
	}
}

// MARK: - LedgerHardwareDevice.View
extension LedgerHardwareDevices {
	public struct ViewState: Equatable {
		var allowSelection: Bool { context != .settings }
		var showIcon: Bool { context != .settings }

		let ledgers: Loadable<IdentifiedArrayOf<LedgerHardwareWalletFactorSource>>
		let selectedLedgerID: FactorSourceID.FromHash?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?
		let context: State.Context

		init(state: LedgerHardwareDevices.State) {
			self.ledgers = state.$ledgers
			self.selectedLedgerID = state.selectedLedgerID

			if let id = state.selectedLedgerID, let selectedLedger = state.ledgers?[id: id] {
				self.selectedLedgerControlRequirements = .init(selectedLedger: selectedLedger)
			} else {
				self.selectedLedgerControlRequirements = nil
			}
			self.context = state.context
		}

		var loadedEmptyLedgersList: Bool { ledgers == .success([]) }

		var ledgersArray: [LedgerHardwareWalletFactorSource]? { .init(ledgers.wrappedValue ?? []) }

		var navigationTitle: String? {
			allowSelection ? nil : L10n.LedgerHardwareDevices.navigationTitleGeneral
		}

		var subtitle: String? {
			switch ledgers {
			case .idle, .loading:
				nil
			case .failure:
				L10n.LedgerHardwareDevices.subtitleFailure
			case .success([]):
				if allowSelection {
					L10n.LedgerHardwareDevices.subtitleSelectLedgerExisting
				} else {
					L10n.LedgerHardwareDevices.subtitleNoLedgers
				}
			case .success:
				if allowSelection {
					L10n.LedgerHardwareDevices.subtitleSelectLedger
				} else {
					L10n.LedgerHardwareDevices.subtitleAllLedgers
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
					VStack(spacing: 0) {
						Group {
							if viewStore.allowSelection {
								Image(asset: AssetResource.iconHardwareLedger)
									.frame(.medium)
									.padding(.vertical, .medium2)

								Text(L10n.LedgerHardwareDevices.navigationTitleAllowSelection)
									.textStyle(.sheetTitle)
									.foregroundColor(.app.gray1)
							}

							if let subtitle = viewStore.subtitle {
								Text(subtitle)
									.foregroundColor(.app.gray1)
									.textStyle(.secondaryHeader)
									.padding(.horizontal, .medium1)
									.padding(.vertical, .medium1)
							}

							//        FIXME: Uncomment and implement
							//        Button(L10n.LedgerHardwareDevices.ledgerFactorSourceInfoCaption) {
							//                viewStore.send(.whatIsALedgerButtonTapped)
							//        }
							//        .buttonStyle(.info)
							//        .flushedLeft
						}
						.multilineTextAlignment(.leading)

						ledgerList(viewStore: viewStore)
							.padding(.horizontal, .medium1)
							.padding(.bottom, .medium1)

						if viewStore.loadedEmptyLedgersList {
							addLedgerButton(viewStore: viewStore)
								.buttonStyle(.primaryRectangular(shouldExpand: false))
						} else {
							addLedgerButton(viewStore: viewStore)
								.buttonStyle(.secondaryRectangular(shouldExpand: false))
						}

						Spacer(minLength: 0)
					}
				}
				.frame(minWidth: 0, maxWidth: .infinity)
				.footer(visible: viewStore.allowSelection) {
					WithControlRequirements(
						viewStore.selectedLedgerControlRequirements,
						forAction: { viewStore.send(.confirmedLedger($0.selectedLedger)) }
					) { action in
						Button(L10n.LedgerHardwareDevices.continueWithLedger, action: action)
							.buttonStyle(.primaryRectangular)
							.padding(.bottom, .medium1)
					}
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}

		private func addLedgerButton(viewStore: ViewStoreOf<LedgerHardwareDevices>) -> some SwiftUI.View {
			Button(L10n.LedgerHardwareDevices.addNewLedger) {
				viewStore.send(.addNewLedgerButtonTapped)
			}
		}

		@ViewBuilder
		private func ledgerList(viewStore: ViewStoreOf<LedgerHardwareDevices>) -> some SwiftUI.View {
			switch viewStore.ledgers {
			case .idle, .loading, .failure, .success([]):
				if viewStore.allowSelection {
					Card(.app.gray5) {
						Text(L10n.LedgerHardwareDevices.subtitleNoLedgers)
							.textStyle(.secondaryHeader)
							.foregroundColor(viewStore.loadedEmptyLedgersList ? .app.gray2 : .clear)
							.padding(.horizontal, .large2)
							.padding(.vertical, .large2 + .small3)
					}
				}

			case let .success(ledgers):
				VStack(spacing: .medium1) {
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
}

private extension StoreOf<LedgerHardwareDevices> {
	var destination: PresentationStoreOf<LedgerHardwareDevices.Destination> {
		func scopeState(state: State) -> PresentationState<LedgerHardwareDevices.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<LedgerHardwareDevices>) -> some View {
		let destinationStore = store.destination
		return addNewLedgerSheet(with: destinationStore)
			.addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
	}

	private func addNewLedgerSheet(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destination.State.addNewLedger,
			action: LedgerHardwareDevices.Destination.Action.addNewLedger,
			content: { AddLedgerFactorSource.View(store: $0) }
		)
	}

	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destination.State.addNewP2PLink,
			action: LedgerHardwareDevices.Destination.Action.addNewP2PLink,
			content: { NewConnection.View(store: $0) }
		)
	}

	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<LedgerHardwareDevices.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /LedgerHardwareDevices.Destination.State.noP2PLink,
			action: LedgerHardwareDevices.Destination.Action.noP2PLink
		)
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - ChooseLedgerHardwareDevice_Preview
// struct ChooseLedgerHardwareDevice_Preview: PreviewProvider {
//	static var previews: some View {
//		ChooseLedgerHardwareDevice.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ChooseLedgerHardwareDevice.init
//			)
//		)
//	}
// }
//
// extension ChooseLedgerHardwareDevice.State {
//	public static let previewValue = Self()
// }
// #endif
