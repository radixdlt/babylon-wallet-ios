import AddLedgerFactorSourceFeature
import FeaturePrelude

// MARK: - LedgerHardwareWallets.View
extension LedgerHardwareWallets {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<LedgerHardwareWallets>

		public init(store: StoreOf<LedgerHardwareWallets>) {
			self.store = store
		}
	}
}

extension LedgerHardwareWallets.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			ScrollView {
				if let ledgers = viewStore.ledgers, !ledgers.isEmpty {
					VStack(spacing: .medium2) {
						ForEach(ledgers) { ledger in
							LedgerRowView(viewState: .init(factorSource: ledger))
								.padding(.horizontal, .medium1)
						}
					}
					.padding(.top, .small1)
				} else {
					Text(L10n.CreateEntity.Ledger.subtitleNoLedgers)
				}

				Spacer(minLength: 0)
			}
			.footer {
				Button(L10n.CreateEntity.Ledger.addNewLedger) {
					viewStore.send(.addNewLedgerButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
			}
			.navigationTitle("Ledger Hardware Wallets") // FIXME: Strings
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.padding(.bottom, .small1)
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
