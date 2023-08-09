import AuthorizedDAppsFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature

// MARK: - AccountSecurity.View
extension AccountSecurity {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension AccountSecurity.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
			ScrollView {
				ForEach(rows) { row in
					PlainListRow(row.icon, title: row.title, subtitle: row.subtitle)
						.tappable {
							viewStore.send(row.action)
						}
						.withSeparator
				}
			}
			.navigationTitle("Account Security") // FIXME: Strings - L10n.Settings.AccountSecurity.title
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.mnemonics(with: destinationStore)
				.ledgerHardwareWallets(with: destinationStore)
				.importFromOlympiaLegacyWallet(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
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
				title: L10n.Settings.importFromLegacyWallet,
				icon: .asset(AssetResource.appSettings),
				action: .importFromOlympiaWalletButtonTapped
			),
		]
	}
}

// MARK: - Extensions

private extension View {
	@MainActor
	func mnemonics(with destinationStore: PresentationStoreOf<AccountSecurity.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destinations.State.mnemonics,
			action: AccountSecurity.Destinations.Action.mnemonics,
			destination: { DisplayMnemonics.View(store: $0) }
		)
	}

	@MainActor
	func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<AccountSecurity.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destinations.State.ledgerHardwareWallets,
			action: AccountSecurity.Destinations.Action.ledgerHardwareWallets,
			destination: {
				LedgerHardwareDevices.View(store: $0)
					.background(.app.gray5)
					.navigationTitle(L10n.Settings.ledgerHardwareWallets)
					.toolbarBackground(.visible, for: .navigationBar)
			}
		)
	}

	@MainActor
	func importFromOlympiaLegacyWallet(with destinationStore: PresentationStoreOf<AccountSecurity.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AccountSecurity.Destinations.State.importOlympiaWalletCoordinator,
			action: AccountSecurity.Destinations.Action.importOlympiaWalletCoordinator,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}
}
