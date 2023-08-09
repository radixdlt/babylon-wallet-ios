import AuthorizedDAppsFeature
import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import LedgerHardwareDevicesFeature
import P2PLinksFeature
import PersonasFeature
import ProfileBackupsFeature
#if DEBUG
import DebugInspectProfileFeature
import EngineKit
import RadixConnectModels // read signaling client url
import SecureStorageClient
import SecurityStructureConfigurationListFeature
#endif

// MARK: - Settings.View
extension Settings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		#if DEBUG
		let debugAppInfo: String
		#endif
		let shouldShowAddP2PLinkButton: Bool
		let appVersion: String

		init(state: Settings.State) {
			#if DEBUG
			let retCommitHash: String = buildInformation().version
			self.debugAppInfo = "RET #\(retCommitHash), SS \(RadixConnectConstants.defaultSignalingServer.absoluteString)"
			#endif

			self.shouldShowAddP2PLinkButton = state.userHasNoP2PLinks ?? false
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.appVersion(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

// MARK: - SettingsRowModel
struct SettingsRowModel<Feature: FeatureReducer>: Identifiable {
	var id: String { title }

	let title: String
	var subtitle: String?
	let icon: AssetIcon.Content
	let action: Feature.ViewAction
}

extension Settings.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
			settingsView(viewStore: viewStore)
				.navigationTitle(L10n.Settings.title)
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.navigationDestinations(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}
}

// MARK: - Extensions

extension Settings.State {
	var viewState: Settings.ViewState {
		.init(state: self)
	}
}

extension Settings.View {
	@MainActor
	private func settingsView(viewStore: ViewStoreOf<Settings>) -> some View {
		ScrollView {
			VStack(spacing: .zero) {
				if viewStore.shouldShowAddP2PLinkButton {
					ConnectExtensionView {
						viewStore.send(.addP2PLinkButtonTapped)
					}
					.padding(.medium3)
				}

				ForEach(rows) { row in
					PlainListRow(row.icon, title: row.title, subtitle: row.subtitle)
						.tappable {
							viewStore.send(row.action)
						}
						.withSeparator
				}
			}
			.padding(.bottom, .large3)

			VStack(spacing: .zero) {
				Text(viewStore.appVersion)
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)
					.padding(.bottom, .medium1)

				#if DEBUG
				Text(viewStore.debugAppInfo)
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)
					.padding(.bottom, .medium1)
				#endif
			}
		}
		.onAppear {
			viewStore.send(.appeared)
		}
	}

	@MainActor
	private var rows: [SettingsRowModel<Settings>] {
		var visibleRows = normalRows
		#if DEBUG
		visibleRows.append(.init(
			title: "Debug Settings",
			icon: .asset(AssetResource.appSettings), // FIXME: Find
			action: .debugButtonTapped
		))
		#endif
		return visibleRows
	}

	@MainActor
	private var normalRows: [SettingsRowModel<Settings>] {
		[
			.init(
				title: L10n.Settings.authorizedDapps,
				icon: .asset(AssetResource.authorizedDapps),
				action: .authorizedDappsButtonTapped
			),
			.init(
				title: L10n.Settings.personas,
				icon: .asset(AssetResource.personas),
				action: .personasButtonTapped
			),
			.init(
				title: "Account Security & Settings", // FIXME: Strings - L10n.Settings.appSettings
				icon: .asset(AssetResource.appSettings), // FIXME: Choose
				action: .accountSecurityButtonTapped
			),
			.init(
				title: L10n.Settings.appSettings,
				icon: .asset(AssetResource.appSettings),
				action: .appSettingsButtonTapped
			),
		]
	}
}

extension View {
	@MainActor
	fileprivate func navigationDestinations(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		self
			.manageP2PLinks(with: destinationStore)
			.authorizedDapps(with: destinationStore)
			.personas(with: destinationStore)
			.accountSecurity(with: destinationStore)
			.appSettings(with: destinationStore)
		#if DEBUG
			.debugSettings(with: destinationStore)
		#endif
	}

	@MainActor
	private func manageP2PLinks(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.manageP2PLinks,
			action: Settings.Destinations.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	@MainActor
	private func authorizedDapps(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.authorizedDapps,
			action: Settings.Destinations.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	@MainActor
	private func personas(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.personas,
			action: Settings.Destinations.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func accountSecurity(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.accountSecurity,
			action: Settings.Destinations.Action.accountSecurity,
			destination: { AccountSecurity.View(store: $0) }
		)
	}

	@MainActor
	private func appSettings(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.appSettings,
			action: Settings.Destinations.Action.appSettings,
			destination: { AppSettings.View(store: $0) }
		)
	}

	#if DEBUG
	@MainActor
	private func debugSettings(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.debugSettings,
			action: Settings.Destinations.Action.debugSettings,
			destination: { DebugSettings.View(store: $0) }
		)
	}
	#endif
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		Settings.View(
			store: .init(
				initialState: .init(),
				reducer: Settings()
			)
		)
	}
}
#endif

// MARK: - ConnectExtensionView
struct ConnectExtensionView: View {
	let action: () -> Void

	var body: some View {
		VStack(spacing: .medium2) {
			Image(asset: AssetResource.browsers)
				.padding([.top, .horizontal], .medium1)

			Text(L10n.Settings.LinkToConnectorHeader.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .medium2)

			Text(L10n.Settings.LinkToConnectorHeader.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .medium2)

			Button(L10n.Settings.LinkToConnectorHeader.linkToConnector, action: action)
				.buttonStyle(.secondaryRectangular(
					shouldExpand: true,
					image: .init(asset: AssetResource.qrCodeScanner)
				))
				.padding([.bottom, .horizontal], .medium1)
		}
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
	}
}

// MARK: - MigrateOlympiaAccountsView
struct MigrateOlympiaAccountsView: View {
	let dismiss: () -> Void
	let action: () -> Void

	var body: some View {
		VStack(spacing: .medium2) {
			Text(L10n.Settings.LinkToConnectorHeader.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .medium2)

			Text(L10n.Settings.LinkToConnectorHeader.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .medium2)

			Button(L10n.Settings.LinkToConnectorHeader.linkToConnector, action: action)
				.buttonStyle(.secondaryRectangular(
					shouldExpand: true,
					image: .init(asset: AssetResource.qrCodeScanner)
				))
				.padding([.bottom, .horizontal], .medium1)
		}
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ConnectExtensionView_Previews: PreviewProvider {
	static var previews: some View {
		ConnectExtensionView {}
	}
}
#endif

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

// MARK: - DebugSettings.View
extension DebugSettings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension DebugSettings.View {
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
			.padding(.bottom, .large3)
			.navigationTitle("Debug Settings") // FIXME: Strings - L10n.Settings.DebugSettings.title
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.factorSources(with: destinationStore)
				.debugInspectProfile(with: destinationStore)
				.securityStructureConfigs(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}

	@MainActor
	private var rows: [SettingsRowModel<DebugSettings>] {
		[
			.init(
				title: L10n.Settings.multiFactor,
				icon: .systemImage("lock.square.stack.fill"),
				action: .securityStructureConfigsButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Factor sources",
				icon: .systemImage("person.badge.key"),
				action: .factorSourcesButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Inspect profile",
				icon: .systemImage("wallet.pass"),
				action: .debugInspectProfileButtonTapped
			),
		]
	}
}

// MARK: - Extensions

private extension View {
	@MainActor
	func factorSources(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.debugManageFactorSources,
			action: DebugSettings.Destinations.Action.debugManageFactorSources,
			destination: { ManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	func debugInspectProfile(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.debugInspectProfile,
			action: DebugSettings.Destinations.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}

	@MainActor
	func securityStructureConfigs(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.securityStructureConfigs,
			action: DebugSettings.Destinations.Action.securityStructureConfigs,
			destination: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
		)
	}
}
