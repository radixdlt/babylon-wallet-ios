import ComposableArchitecture
import SwiftUI
extension AccountSecurity.State {
	var viewState: AccountSecurity.ViewState {
		.init(state: self)
	}
}

// MARK: - AccountSecurity.View
extension AccountSecurity {
	public struct ViewState: Equatable {
		public let canImportOlympiaWallet: Bool

		init(state: AccountSecurity.State) {
			self.canImportOlympiaWallet = state.canImportOlympiaWallet
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store
		private let destinationStore: PresentationStoreOf<Destination>

		public init(store: Store) {
			self.store = store
			self.destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		}
	}
}

extension AccountSecurity.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEach(rows) { row in
						SettingsRow(row: row) {
							store.send(.view(row.action))
						}
					}

					if let row = importOlympiaRow(with: viewStore) {
						SettingsRow(row: row) {
							store.send(.view(row.action))
						}
					}
				}
			}
			.onAppear {
				store.send(.view(.appeared))
			}
			.navigationTitle(L10n.Settings.accountSecurityAndSettings)
			.navigationBarTitleColor(.app.gray1)
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarInlineTitleFont(.app.secondaryHeader)
			.mnemonics(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
			.depositGuarantees(with: destinationStore)
			.importFromOlympiaLegacyWallet(with: destinationStore)
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
			.presentsLoadingViewOverlay()
		}
	}

	@MainActor
	private var rows: [SettingsRowModel<AccountSecurity>] {
		[
			.init(
				title: L10n.SeedPhrases.title,
				icon: .asset(AssetResource.ellipsis),
				action: .mnemonicsButtonTapped
			),
			.init(
				title: L10n.Settings.ledgerHardwareWallets,
				icon: .asset(AssetResource.ledger),
				action: .ledgerHardwareWalletsButtonTapped
			),
			.init(
				title: L10n.Settings.DepositGuarantees.title,
				subtitle: L10n.Settings.DepositGuarantees.subtitle,
				icon: .asset(AssetResource.depositGuarantees),
				action: .defaultDepositGuaranteeButtonTapped
			),
		]
	}

	@MainActor
	private func importOlympiaRow(
		with viewStore: ViewStoreOf<AccountSecurity>
	) -> SettingsRowModel<AccountSecurity>? {
		guard viewStore.canImportOlympiaWallet else {
			return nil
		}

		return .init(
			title: L10n.Settings.importFromLegacyWallet,
			subtitle: nil,
			icon: .asset(AssetResource.appSettings),
			action: .importFromOlympiaWalletButtonTapped
		)
	}
}

// MARK: - Extensions

private extension View {
	@MainActor
	func mnemonics(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.mnemonics,
			action: AccountSecurity.Destination.Action.mnemonics,
			destination: { DisplayMnemonics.View(store: $0) }
		)
	}

	@MainActor
	func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.ledgerHardwareWallets,
			action: AccountSecurity.Destination.Action.ledgerHardwareWallets,
			destination: {
				LedgerHardwareDevices.View(store: $0)
					.background(.app.gray5)
					.navigationTitle(L10n.Settings.ledgerHardwareWallets)
					.toolbarBackground(.visible, for: .navigationBar)
			}
		)
	}

	@MainActor
	func depositGuarantees(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.depositGuarantees,
			action: AccountSecurity.Destination.Action.depositGuarantees,
			destination: { DefaultDepositGuarantees.View(store: $0) }
		)
	}

	@MainActor
	func importFromOlympiaLegacyWallet(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.importOlympiaWallet,
			action: AccountSecurity.Destination.Action.importOlympiaWallet,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}
}
