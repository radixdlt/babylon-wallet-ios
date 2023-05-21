import AuthorizedDAppsFeature
import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import GeneralSettings
import P2PLinksFeature
import PersonasFeature
import ProfileBackupsFeature
#if DEBUG
import EngineToolkit // read RET commit hash
import InspectProfileFeature
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
		let isDebugProfileViewSheetPresented: Bool
		let profileToInspect: Profile?
		let debugAppInfo: String
		#endif
		let shouldShowAddP2PLinkButton: Bool
		let appVersion: String

		init(state: AppSettings.State) {
			#if DEBUG
			self.isDebugProfileViewSheetPresented = state.profileToInspect != nil
			self.profileToInspect = state.profileToInspect
			let retCommitHash: String = {
				do {
					return try EngineToolkit().information().get().lastCommitHash
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
			settingsView(viewStore: viewStore)
				.navigationTitle(L10n.Settings.title)
			#if os(iOS)
				.navigationBarTitleDisplayMode(.inline)
			#endif
				.navigationDestinations(with: store, viewStore)
				.confirmationDialog(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
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
	fileprivate func navigationDestinations(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self
		#if DEBUG
			.navigationDestination(
				isPresented: viewStore.binding(
					get: \.isDebugProfileViewSheetPresented,
					send: { .setDebugProfileSheet(isPresented: $0) }
				)
			) {
				if let profile = viewStore.profileToInspect {
					ProfileView(
						profile: profile,
						// Sorry about this, hacky hacky hack. But it is only for debugging and we are short on time..
						secureStorageClient: SecureStorageClient.liveValue
					)
				} else {
					Text(L10n.Settings.noProfileText)
				}
			}
		#endif
			.importFromOlympiaLegacyWallet(with: store)
			.factorSources(with: store)
			.manageP2PLinks(with: store)
			.gatewaySettings(with: store)
			.authorizedDapps(with: store)
			.personas(with: store)
			.generalSettings(with: store)
			.profileBackups(with: store)
	}
}

extension View {
	@MainActor
	private func importFromOlympiaLegacyWallet(with store: StoreOf<AppSettings>) -> some View {
		self.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.importOlympiaWalletCoordinator,
			action: AppSettings.Destinations.Action.importOlympiaWalletCoordinator,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func factorSources(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.manageFactorSources,
			action: AppSettings.Destinations.Action.manageFactorSources,
			destination: { ManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	private func manageP2PLinks(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.manageP2PLinks,
			action: AppSettings.Destinations.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	@MainActor
	private func gatewaySettings(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.gatewaySettings,
			action: AppSettings.Destinations.Action.gatewaySettings,
			destination: { GatewaySettings.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func authorizedDapps(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.authorizedDapps,
			action: AppSettings.Destinations.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func personas(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.personas,
			action: AppSettings.Destinations.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func generalSettings(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.generalSettings,
			action: AppSettings.Destinations.Action.generalSettings,
			destination: { GeneralSettings.View(store: $0) }
		)
	}

	@MainActor
	private func profileBackups(with store: StoreOf<AppSettings>) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.profileBackups,
			action: AppSettings.Destinations.Action.profileBackups,
			destination: { ProfileBackups.View(store: $0) }
		)
	}
}

// MARK: - SettingsRowModel

extension AppSettings.View {
	struct RowModel: Identifiable {
		var id: String { title }
		let title: String
		let subtitle: String?
		let asset: ImageAsset
		let action: AppSettings.ViewAction

		init(title: String, subtitle: String? = nil, asset: ImageAsset, action: AppSettings.ViewAction) {
			self.title = title
			self.subtitle = subtitle
			self.asset = asset
			self.action = action
		}
	}

	@MainActor
	private func settingsRows() -> [RowModel] {
		[
			.init(
				title: L10n.Settings.linkedConnectors,
				asset: AssetResource.desktopConnections,
				action: .manageP2PLinksButtonTapped
			),
			.init(
				title: L10n.Settings.gateways,
				asset: AssetResource.gateway,
				action: .gatewaysButtonTapped
			),
			.init(
				title: L10n.Settings.authorizedDapps,
				asset: AssetResource.authorizedDapps,
				action: .authorizedDappsButtonTapped
			),
			.init(
				title: L10n.Settings.personas,
				asset: AssetResource.personas,
				action: .personasButtonTapped
			),
			.init(
				title: L10n.Settings.appSettings,
				asset: AssetResource.generalSettings,
				action: .generalSettingsButtonTapped
			),
			.init(
				title: L10n.Settings.backups,
				subtitle: nil, // TODO: Determine, if possible, the date of last backup.
				asset: AssetResource.backups,
				action: .profileBackupsTapped
			),
		]
	}

	@MainActor
	private func settingsView(viewStore: ViewStoreOf<AppSettings>) -> some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(spacing: .zero) {
					if viewStore.shouldShowAddP2PLinkButton {
						ConnectExtensionView {
							viewStore.send(.addP2PLinkButtonTapped)
						}
						.padding(.medium3)
					}

					#if DEBUG
					PlainListRow(title: L10n.Settings.inspectProfile) {
						Image(systemName: "wallet.pass")
							.frame(.verySmall)
					}
					.tappable {
						viewStore.send(.debugInspectProfileButtonTapped)
					}
					.withSeparator

					PlainListRow(title: "Factor Sources") {
						Image(systemName: "person.badge.key")
							.frame(.verySmall)
					}
					.tappable {
						viewStore.send(.factorSourcesButtonTapped)
					}
					.withSeparator

					PlainListRow(title: L10n.Settings.importFromLegacyWallet, asset: AssetResource.generalSettings)
						.tappable {
							viewStore.send(.importFromOlympiaWalletButtonTapped)
						}
						.withSeparator
					#endif

					ForEach(settingsRows()) { row in
						PlainListRow(title: row.title, asset: row.asset)
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
