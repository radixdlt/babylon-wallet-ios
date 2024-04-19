private typealias S = L10n.Troubleshooting

// MARK: - Troubleshooting.View
public extension Troubleshooting {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Troubleshooting>

		public init(store: StoreOf<Troubleshooting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.setUpNavigationBar(title: S.title)
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
		ScrollView {
			VStack(spacing: .zero) {
				ForEach(rows) { kind in
					SettingsRow(kind: kind, store: store)
				}
			}
		}
		.background(Color.app.gray4)
	}

	@MainActor
	private var rows: [SettingsRow<Troubleshooting>.Kind] {
		[
			.header(S.accountRecovery),
			.model(
				title: S.AccountScan.title,
				subtitle: S.AccountScan.subtitle,
				icon: .asset(AssetResource.recovery),
				action: .accountScanButtonTapped
			),
			.model(
				title: S.LegacyImport.title,
				subtitle: S.LegacyImport.subtitle,
				icon: .asset(AssetResource.recovery),
				action: .legacyImportButtonTapped
			),
			.header(S.supportAndCommunity),
			.model(
				title: S.ContactSupport.title,
				subtitle: S.ContactSupport.subtitle,
				icon: .systemImage("envelope"),
				action: .contactSupportButtonTapped
			),
			.model(
				title: S.Discord.title,
				subtitle: S.Discord.subtitle,
				icon: .asset(AssetResource.discord),
				accessory: .iconLinkOut,
				action: .discordButtonTapped
			),
		]
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
}
