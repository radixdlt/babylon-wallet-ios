import AddLedgerFactorSourceFeature
import DerivePublicKeysFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature
import NewConnectionFeature

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			ledgerControlledAccounts: olympiaAccounts.unvalidated.count + olympiaAccounts.validated.count,
			knownLedgers: knownLedgers,
			moreAccounts: olympiaAccounts.unvalidated.count
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources.View
extension ImportOlympiaLedgerAccountsAndFactorSources {
	public struct ViewState: Equatable {
		public let ledgerControlledAccounts: Int
		public let knownLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>
		public let moreAccounts: Int
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>

		public init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(alignment: .center, spacing: .medium2) {
						Text(L10n.ImportOlympiaLedgerAccounts.title)
							.textStyle(.sheetTitle)
							.padding(.top, .small1)

						Text(L10n.ImportOlympiaLedgerAccounts.subtitle(viewStore.ledgerControlledAccounts))
							.textStyle(.body1Header)
							.padding(.horizontal, .large3)

						Text(L10n.ImportOlympiaLedgerAccounts.listHeading)
							.textStyle(.body1Header)

						if viewStore.knownLedgers.isEmpty {
							Card(.app.gray5) {
								Text(L10n.ImportOlympiaLedgerAccounts.knownLedgersNone)
									.textStyle(.secondaryHeader)
									.frame(height: .largeButtonHeight)
									.frame(maxWidth: .infinity)
							}
							.padding(.horizontal, .medium3)
						} else {
							ForEach(viewStore.knownLedgers) { ledger in
								VStack(spacing: .small1) {
									LedgerRowView(viewState: .init(factorSource: ledger))
										.padding(.horizontal, .medium3)
								}
							}
						}

						if viewStore.moreAccounts > 0 {
							Text(L10n.ImportOlympiaLedgerAccounts.otherDeviceAccounts(viewStore.moreAccounts))
								.textStyle(.body1Regular)
								.padding(.horizontal, .large3)
						}

						Spacer(minLength: 0)
					}
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
				}
				.footer(visible: viewStore.moreAccounts > 0) {
					Button(L10n.ImportOlympiaLedgerAccounts.continueButtonTitle) {
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.destinations(with: store)
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
			.nameLedgerSheet(with: destinationStore)
			.noAccountsOnLedgerAlert(with: destinationStore)
	}

	@MainActor
	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.noP2PLink,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.noP2PLink
		)
	}

	@MainActor
	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.addNewP2PLink,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.addNewP2PLink,
			content: { NewConnection.View(store: $0) }
		)
	}

	@MainActor
	private func nameLedgerSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.nameLedgerAndDerivePublicKeys,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.nameLedgerAndDerivePublicKeys,
			content: { NameLedgerAndDerivePublicKeys.View(store: $0) }
		)
	}

	@MainActor
	private func noAccountsOnLedgerAlert(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.noAccountsOnLedger,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.noAccountsOnLedger
		)
	}
}

// MARK: - NameLedgerAndDerivePublicKeys.View
extension NameLedgerAndDerivePublicKeys {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameLedgerAndDerivePublicKeys>

		public init(store: StoreOf<NameLedgerAndDerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				IfLetStore(store.scope(state: \.nameLedger, action: { .child(.nameLedger($0)) })) { childStore in
					NameLedgerFactorSource.View(store: childStore)
				} else: {
					Rectangle()
						.fill(.clear)
				}
				.navigationDestination(
					store: store.scope(state: \.$derivePublicKeys, action: { .child(.derivePublicKeys($0)) })
				) {
					DerivePublicKeys.View(store: $0)
						.navigationBarBackButtonHidden()
				}
			}
		}
	}
}
