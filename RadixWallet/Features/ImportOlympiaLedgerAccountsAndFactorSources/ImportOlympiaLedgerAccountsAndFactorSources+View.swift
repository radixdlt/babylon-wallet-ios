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
						Spacer(minLength: 0)
					}
					.foregroundColor(.app.gray1)
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
		func scopeState(state: State) -> PresentationState<ImportOlympiaLedgerAccountsAndFactorSources.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
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
		alert(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destination.State.noP2PLink,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destination.Action.noP2PLink
		)
	}

	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destination.State.addNewP2PLink,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destination.Action.addNewP2PLink,
			content: { NewConnection.View(store: $0) }
		)
	}

	private func nameLedgerSheet(with destinationStore: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportOlympiaLedgerAccountsAndFactorSources.Destination.State.nameLedgerAndDerivePublicKeys,
			action: ImportOlympiaLedgerAccountsAndFactorSources.Destination.Action.nameLedgerAndDerivePublicKeys,
			content: { ImportOlympiaNameLedgerAndDerivePublicKeys.View(store: $0) }
		)
	}
}
