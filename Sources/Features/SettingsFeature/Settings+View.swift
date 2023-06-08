import AuthorizedDAppsFeature
import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import GeneralSettings
import LedgerHardwareDevicesFeature
import P2PLinksFeature
import PersonasFeature
import ProfileBackupsFeature
#if DEBUG
import DebugInspectProfileFeature
import EngineToolkit // read RET commit hash
import RadixConnectModels // read signaling client url
import SecureStorageClient
#endif

// MARK: - AppSettings.View
extension AppSettings {
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

		init(state: AppSettings.State) {
			#if DEBUG
			let retCommitHash: String = {
				do {
					return try RadixEngine.instance.information().get().lastCommitHash
				} catch {
					return "Unknown"
				}
			}()
			self.debugAppInfo = "RET #\(retCommitHash), SS \(RadixConnectConstants.defaultSignalingServer.absoluteString)"
			#endif

			self.shouldShowAddP2PLinkButton = state.userHasNoP2PLinks ?? false
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.appVersion(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

extension AppSettings.View {
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
				.confirmationDialog(
					store: destinationStore,
					state: /AppSettings.Destinations.State.deleteProfileConfirmationDialog,
					action: AppSettings.Destinations.Action.deleteProfileConfirmationDialog
				)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}
}

// MARK: - Extensions

extension AppSettings.State {
	var viewState: AppSettings.ViewState {
		.init(state: self)
	}
}

extension View {
	// NB: this function is split out from the body so the compiler doesn't choke
	// ("... compiler is unable to type-check this expression in reasonable time...").
	//
	// Maybe the new result builder performance improvements in Swift 5.8 will correct this.
	@MainActor
	fileprivate func navigationDestinations(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		self
			.manageP2PLinks(with: destinationStore)
			.gatewaySettings(with: destinationStore)
			.authorizedDapps(with: destinationStore)
			.personas(with: destinationStore)
			.generalSettings(with: destinationStore)
			.profileBackups(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
			.mnemonics(with: destinationStore)
		#if DEBUG
			.importFromOlympiaLegacyWallet(with: destinationStore)
			.factorSources(with: destinationStore)
			.debugInspectProfile(with: destinationStore)
		#endif // DEBUG
	}

	@MainActor
	private func manageP2PLinks(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.manageP2PLinks,
			action: AppSettings.Destinations.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	@MainActor
	private func gatewaySettings(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.gatewaySettings,
			action: AppSettings.Destinations.Action.gatewaySettings,
			destination: { GatewaySettings.View(store: $0) }
		)
	}

	@MainActor
	private func authorizedDapps(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.authorizedDapps,
			action: AppSettings.Destinations.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	@MainActor
	private func personas(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.personas,
			action: AppSettings.Destinations.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func generalSettings(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.generalSettings,
			action: AppSettings.Destinations.Action.generalSettings,
			destination: { GeneralSettings.View(store: $0) }
		)
	}

	@MainActor
	private func profileBackups(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.profileBackups,
			action: AppSettings.Destinations.Action.profileBackups,
			destination: { ProfileBackups.View(store: $0) }
		)
	}

	@MainActor
	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.ledgerHardwareWallets,
			action: AppSettings.Destinations.Action.ledgerHardwareWallets,
			destination: { LedgerHardwareDevices.View(store: $0) }
		)
	}

	@MainActor
	private func mnemonics(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.mnemonics,
			action: AppSettings.Destinations.Action.mnemonics,
			destination: { DisplayMnemonics.View(store: $0) }
		)
	}

	#if DEBUG
	@MainActor
	private func importFromOlympiaLegacyWallet(with destinationStore: PresentationStoreOf<AppSettings.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AppSettings.Destinations.State.importOlympiaWalletCoordinator,
			action: AppSettings.Destinations.Action.importOlympiaWalletCoordinator,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func factorSources(
		with destinationStore: PresentationStoreOf<AppSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.debugManageFactorSources,
			action: AppSettings.Destinations.Action.debugManageFactorSources,
			destination: { ManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	private func debugInspectProfile(
		with destinationStore: PresentationStoreOf<AppSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destinations.State.debugInspectProfile,
			action: AppSettings.Destinations.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}
	#endif
}

// MARK: - SettingsRowModel

extension AppSettings.View {
	struct RowModel: Identifiable {
		var id: String { title }

		let title: String
		var subtitle: String?
		let icon: AssetIcon.Content
		let action: AppSettings.ViewAction
	}

	@MainActor
	private func settingsView(viewStore: ViewStoreOf<AppSettings>) -> some View {
		VStack(spacing: .zero) {
			ScrollView {
				VStack(spacing: .zero) {
					if viewStore.shouldShowAddP2PLinkButton {
						ConnectExtensionView {
							viewStore.send(.addP2PLinkButtonTapped)
						}
						.padding(.medium3)
					}

					ForEach(settingsRows()) { row in
						PlainListRow(row.icon, title: row.title)
							.tappable {
								viewStore.send(row.action)
							}
							.withSeparator
					}
				}
				.padding(.bottom, .large3)
				VStack(spacing: .zero) {
					Button(L10n.Settings.deleteWalletData) {
						viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(isDestructive: true))
					.padding(.bottom, .large1)

					Text(viewStore.appVersion)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.padding(.bottom, .medium1)

					#if DEBUG
					Text(viewStore.debugAppInfo)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.padding(.bottom, .medium1)
					#endif // DEBUG
				}
			}
			.onAppear {
				viewStore.send(.appeared)
			}
		}
	}

	@MainActor
	private func settingsRows() -> [RowModel] {
		var models: [RowModel] = [
			.init(
				title: L10n.Settings.linkedConnectors,
				icon: .asset(AssetResource.desktopConnections),
				action: .manageP2PLinksButtonTapped
			),
			.init(
				title: L10n.Settings.gateways,
				icon: .asset(AssetResource.gateway),
				action: .gatewaysButtonTapped
			),
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
				title: L10n.Settings.appSettings,
				icon: .asset(AssetResource.generalSettings),
				action: .generalSettingsButtonTapped
			),
			.init(
				title: L10n.Settings.backups,
				subtitle: nil, // TODO: Determine, if possible, the date of last backup.
				icon: .asset(AssetResource.backups),
				action: .profileBackupsButtonTapped
			),
			.init(
				title: L10n.Settings.ledgerHardwareWallets,
				icon: .asset(AssetResource.ledger),
				action: .ledgerHardwareWalletsButtonTapped
			),
		]

		#if DEBUG
		models.append(contentsOf: [
			.init(
				title: L10n.Settings.importFromLegacyWallet,
				icon: .asset(AssetResource.generalSettings),
				action: .importFromOlympiaWalletButtonTapped
			),
			.init( // ONLY DEBUG EVER
				title: L10n.Settings.Debug.factorSources,
				icon: .systemImage("person.badge.key"),
				action: .factorSourcesButtonTapped
			),
			.init( // ONLY DEBUG EVER
				title: L10n.Settings.Debug.inspectProfile,
				icon: .systemImage("wallet.pass"),
				action: .debugInspectProfileButtonTapped
			),
			.init(
				title: L10n.DisplayMnemonics.seedPhrases,
				icon: .asset(AssetResource.ellipsis),
				action: .mnemonicsButtonTapped
			),
		])
		#endif

		return models
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		AppSettings.View(
			store: .init(
				initialState: .init(),
				reducer: AppSettings()
			)
		)
	}
}
#endif

// MARK: - ConnectExtensionView
struct ConnectExtensionView: View {
	let action: () -> Void
}

extension ConnectExtensionView {
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ConnectExtensionView_Previews: PreviewProvider {
	static var previews: some View {
		ConnectExtensionView {}
	}
}
#endif
