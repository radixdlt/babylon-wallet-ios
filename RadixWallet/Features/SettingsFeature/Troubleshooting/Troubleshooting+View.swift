extension Troubleshooting.State {
	var viewState: Troubleshooting.ViewState {
		.init(isLegacyImportEnabled: isLegacyImportEnabled)
	}
}

// MARK: - Troubleshooting.View
public extension Troubleshooting {
	struct ViewState: Equatable {
		let isLegacyImportEnabled: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Troubleshooting>

		public init(store: StoreOf<Troubleshooting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.radixNavigationBar(title: L10n.Troubleshooting.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

extension Troubleshooting.View {
	@MainActor
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEachStatic(rows(isLegacyImportEnabled: viewStore.isLegacyImportEnabled)) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}
			}
			.background(Color.app.gray5)
			.onFirstTask { @MainActor in
				await viewStore.send(.onFirstTask).finish()
			}
		}
	}

	@MainActor
	private func rows(isLegacyImportEnabled: Bool) -> [SettingsRow<Troubleshooting>.Kind] {
		[
			.header(L10n.Troubleshooting.accountRecovery),
			.model(
				title: L10n.Troubleshooting.AccountScan.title,
				subtitle: L10n.Troubleshooting.AccountScan.subtitle,
				icon: .asset(AssetResource.recovery),
				action: .accountScanButtonTapped
			),
			.model(
				title: L10n.Troubleshooting.LegacyImport.title,
				subtitle: L10n.Troubleshooting.LegacyImport.subtitle,
				icon: .asset(AssetResource.recovery),
				action: .legacyImportButtonTapped
			).valid(if: isLegacyImportEnabled),
			.header(L10n.Troubleshooting.supportAndCommunity),
			.model(
				title: L10n.Troubleshooting.ContactSupport.title,
				subtitle: L10n.Troubleshooting.ContactSupport.subtitle,
				icon: .systemImage("envelope"),
				accessory: .iconLinkOut,
				action: .contactSupportButtonTapped
			),
			.model(
				title: L10n.Troubleshooting.Discord.title,
				subtitle: L10n.Troubleshooting.Discord.subtitle,
				icon: .asset(AssetResource.discord),
				accessory: .iconLinkOut,
				action: .discordButtonTapped
			),
			.header(L10n.Troubleshooting.resetAccount),
			.model(
				title: L10n.Troubleshooting.FactoryReset.title,
				subtitle: L10n.Troubleshooting.FactoryReset.subtitle,
				icon: .systemImage("arrow.clockwise"),
				action: .factoryResetButtonTapped
			),
		]
		.compactMap { $0 }
	}
}

// MARK: - Extensions

private extension StoreOf<Troubleshooting> {
	var destination: PresentationStoreOf<Troubleshooting.Destination> {
		func scopeState(state: State) -> PresentationState<Troubleshooting.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Troubleshooting>) -> some View {
		let destinationStore = store.destination
		return accountRecovery(with: destinationStore)
			.importOlympiaWallet(with: destinationStore)
			.factoryReset(with: destinationStore)
	}

	private func accountRecovery(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.accountRecovery,
			action: Troubleshooting.Destination.Action.accountRecovery,
			content: { ManualAccountRecoveryCoordinator.View(store: $0) }
		)
	}

	private func importOlympiaWallet(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.importOlympiaWallet,
			action: Troubleshooting.Destination.Action.importOlympiaWallet,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}

	private func factoryReset(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.factoryReset,
			action: Troubleshooting.Destination.Action.factoryReset,
			destination: { FactoryReset.View(store: $0) }
		)
	}
}

private extension SettingsRow.Kind {
	func valid(if condition: Bool) -> Self? {
		condition ? self : nil
	}
}
