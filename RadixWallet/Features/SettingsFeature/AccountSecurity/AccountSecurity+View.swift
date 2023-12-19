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

		public init(store: Store) {
			self.store = store
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

					if viewStore.canImportOlympiaWallet {
						let row = importOlympiaRow
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
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
			.presentsLoadingViewOverlay()
		}
		.destinations(with: store)
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
				title: L10n.AccountSecuritySettings.LedgerHardwareWallets.title,
				icon: .asset(AssetResource.ledger),
				action: .ledgerHardwareWalletsButtonTapped
			),
			.init(
				title: L10n.AccountSecuritySettings.DepositGuarantees.title,
				subtitle: L10n.AccountSecuritySettings.DepositGuarantees.subtitle,
				icon: .asset(AssetResource.depositGuarantees),
				action: .defaultDepositGuaranteeButtonTapped
			),
			.init(
				title: L10n.AccountSecuritySettings.AccountRecoveryScan.title,
				subtitle: L10n.AccountSecuritySettings.AccountRecoveryScan.subtitle,
				icon: .asset(AssetResource.appSettings), // TODO: Select asset
				action: .accountRecoveryButtonTapped
			),
			.init(
				title: L10n.AccountSecuritySettings.Backups.title,
				subtitle: nil, // TODO: Determine, if possible, the date of last backup.
				icon: .asset(AssetResource.backups),
				action: .profileBackupSettingsButtonTapped
			),
		]
	}

	@MainActor
	private var importOlympiaRow: SettingsRowModel<AccountSecurity> {
		.init(
			title: L10n.AccountSecuritySettings.ImportFromLegacyWallet.title,
			subtitle: nil,
			icon: .asset(AssetResource.appSettings),
			action: .importFromOlympiaWalletButtonTapped
		)
	}
}

// MARK: - Extensions

private extension StoreOf<AccountSecurity> {
	var destination: PresentationStoreOf<AccountSecurity.Destination> {
		func scopeState(state: State) -> PresentationState<AccountSecurity.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AccountSecurity>) -> some View {
		let destinationStore = store.destination
		return mnemonics(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
			.depositGuarantees(with: destinationStore)
			.importFromOlympiaLegacyWallet(with: destinationStore)
			.accountRecovery(with: destinationStore)
			.profileBackupSettings(with: destinationStore)
	}

	private func mnemonics(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.mnemonics,
			action: AccountSecurity.Destination.Action.mnemonics,
			destination: { DisplayMnemonics.View(store: $0) }
		)
	}

	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.ledgerHardwareWallets,
			action: AccountSecurity.Destination.Action.ledgerHardwareWallets,
			destination: {
				LedgerHardwareDevices.View(store: $0)
					.background(.app.gray5)
					.navigationTitle(L10n.AccountSecuritySettings.LedgerHardwareWallets.title)
					.toolbarBackground(.visible, for: .navigationBar)
			}
		)
	}

	private func depositGuarantees(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.depositGuarantees,
			action: AccountSecurity.Destination.Action.depositGuarantees,
			destination: { DefaultDepositGuarantees.View(store: $0) }
		)
	}

	private func importFromOlympiaLegacyWallet(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.importOlympiaWallet,
			action: AccountSecurity.Destination.Action.importOlympiaWallet,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}

	private func accountRecovery(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.accountRecovery,
			action: AccountSecurity.Destination.Action.accountRecovery,
			content: { ManualAccountRecoveryCoordinator.View(store: $0) }
		)
	}

	private func profileBackupSettings(with destinationStore: PresentationStoreOf<AccountSecurity.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountSecurity.Destination.State.profileBackupSettings,
			action: AccountSecurity.Destination.Action.profileBackupSettings,
			destination: { ProfileBackupSettings.View(store: $0) }
		)
	}
}
