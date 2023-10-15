import ComposableArchitecture
import SwiftUI
extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			knownLedgers: knownLedgers,
			migrated: migratedAccounts,
			moreAccounts: olympiaAccounts.unvalidated.count
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources.View
extension ImportOlympiaLedgerAccountsAndFactorSources {
	public struct ViewState: Equatable {
		public let usedLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>
		public let moreAccounts: Int

		public init(
			knownLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>,
			migrated: [MigratedHardwareAccounts],
			moreAccounts: Int
		) {
			let usedLedgerIDs = Set(migrated.map(\.ledgerID))
			self.usedLedgers = knownLedgers.filter { usedLedgerIDs.contains($0.id) }
			self.moreAccounts = moreAccounts
		}
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
					VStack(alignment: .center, spacing: .medium3) {
						Group {
							Text(L10n.ImportOlympiaLedgerAccounts.title)
								.textStyle(.sheetTitle)

							Text(L10n.ImportOlympiaLedgerAccounts.subtitle)
								.textStyle(.body1Regular)

							Text(L10n.ImportOlympiaLedgerAccounts.accountCount(viewStore.moreAccounts))
								.textStyle(.body1Header)
						}
						.padding(.horizontal, .large2)

						if !viewStore.usedLedgers.isEmpty {
							Text(L10n.ImportOlympiaLedgerAccounts.listHeading)
								.textStyle(.body1Header)
								.padding(.top, .medium3)
								.padding(.horizontal, .large2)

							ForEach(viewStore.usedLedgers) { ledger in
								Card(.app.gray5) {
									Text(ledger.hint.name)
										.textStyle(.secondaryHeader)
										.multilineTextAlignment(.leading)
										.flushedLeft
										.padding(.horizontal, .large3)
										.padding(.vertical, .medium1)
								}
							}
							.padding(.horizontal, .medium3)
						}

						if viewStore.moreAccounts > 0 {
							Text(L10n.ImportOlympiaLedgerAccounts.subtitle)
								.textStyle(.body1Regular)
								.padding(.horizontal, .large2)
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
