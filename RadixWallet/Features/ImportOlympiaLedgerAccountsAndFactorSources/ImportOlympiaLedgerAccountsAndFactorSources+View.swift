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
	struct ViewState: Equatable {
		let usedLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>
		let moreAccounts: Int

		init(
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
	struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>

		init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(alignment: .center, spacing: .medium3) {
						Group {
							Text(L10n.ImportOlympiaLedgerAccounts.title)
								.textStyle(.sheetTitle)

							if viewStore.moreAccounts > 0 {
								Text(L10n.ImportOlympiaLedgerAccounts.subtitle)
									.textStyle(.body1Regular)
							}

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
								Card {
									Text(ledger.hint.label)
										.textStyle(.secondaryHeader)
										.multilineTextAlignment(.leading)
										.flushedLeft
										.padding(.horizontal, .large3)
										.padding(.vertical, .medium1)
								}
							}
							.padding(.horizontal, .medium3)
						}
						Spacer(minLength: 0)
					}
					.foregroundColor(.primaryText)
					.multilineTextAlignment(.center)
				}
				.navigationBarBackButtonHidden()
				.footer(visible: viewStore.moreAccounts > 0) {
					Button(L10n.ImportOlympiaLedgerAccounts.continueButtonTitle) {
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<ImportOlympiaLedgerAccountsAndFactorSources> {
	var destination: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) -> some View {
		let destinationStore = store.destination
		return addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
			.nameLedgerSheet(with: destinationStore)
	}

	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.noP2PLink, action: \.noP2PLink))
	}

	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewP2PLink, action: \.addNewP2PLink)) {
			NewConnection.View(store: $0)
		}
	}

	private func nameLedgerSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.nameLedger, action: \.nameLedger)) {
			ImportOlympiaNameLedger.View(store: $0)
		}
	}
}
