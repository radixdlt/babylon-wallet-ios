import AuthorizedDAppsFeatures
import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import P2PLinksFeature
import PersonasFeature
#if DEBUG
import InspectProfileFeature
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
		#endif
		let shouldShowAddP2PLinkButton: Bool
		let appVersion: String

		init(state: AppSettings.State) {
			#if DEBUG
			self.isDebugProfileViewSheetPresented = state.profileToInspect != nil
			self.profileToInspect = state.profileToInspect
			#endif
			self.shouldShowAddP2PLinkButton = state.userHasNoP2PLinks ?? false
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.versionInfo(bundleInfo.shortVersion, bundleInfo.version)
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
			.importFromOlympiaLegacyWallet(with: store, viewStore)
			.factorSources(with: store, viewStore)
			.manageP2PLinks(with: store, viewStore)
			.manageGatewayAPIEndpoints(with: store, viewStore)
			.authorizedDapps(with: store, viewStore)
			.personas(with: store, viewStore)
	}
}

extension View {
	@MainActor
	private func importFromOlympiaLegacyWallet(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.importFromOlympiaLegacyWallet,
			action: AppSettings.Destinations.Action.importFromOlympiaLegacyWallet,
			destination: { ImportFromOlympiaLegacyWallet.View(store: $0) }
		)
	}

	@MainActor
	private func factorSources(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.manageFactorSources,
			action: AppSettings.Destinations.Action.manageFactorSources,
			destination: { ManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	private func manageP2PLinks(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.manageP2PLinks,
			action: AppSettings.Destinations.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	@MainActor
	private func manageGatewayAPIEndpoints(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.gatewaySettings,
			action: AppSettings.Destinations.Action.gatewaySettings,
			destination: { GatewaySettings.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func authorizedDapps(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.authorizedDapps,
			action: AppSettings.Destinations.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func personas(
		with store: StoreOf<AppSettings>,
		_ viewStore: ViewStoreOf<AppSettings>
	) -> some View {
		self.navigationDestination(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /AppSettings.Destinations.State.personas,
			action: AppSettings.Destinations.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}
}

// MARK: - SettingsRowModel

extension AppSettings.View {
	struct RowModel: Identifiable {
		var id: String { title }
		let title: String
		let asset: ImageAsset
		let action: AppSettings.ViewAction
	}

	private func settingsRows() -> [RowModel] {
		[
			.init(
				title: L10n.Settings.desktopConnectionsButtonTitle,
				asset: AssetResource.desktopConnections,
				action: .manageP2PLinksButtonTapped
			),
			.init(
				title: L10n.Settings.gatewaysButtonTitle,
				asset: AssetResource.gateway,
				action: .gatewaysButtonTapped
			),
			.init(
				title: L10n.Settings.authorizedDappsButtonTitle,
				asset: AssetResource.authorizedDapps,
				action: .authorizedDappsButtonTapped
			),
			.init(
				title: L10n.Settings.personasButtonTitle,
				asset: AssetResource.personas,
				action: .personasButtonTapped
			),
			.init(
				title: L10n.Settings.appSettingsButtonTitle,
				asset: AssetResource.appSettings,
				action: .appSettingsButtonTapped
			),
		]
	}

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
					PlainListRow(title: L10n.Settings.inspectProfileButtonTitle) {
						viewStore.send(.debugInspectProfileButtonTapped)
					} icon: {
						Image(systemName: "wallet.pass")
							.frame(.verySmall)
					}
					.withSeparator
					.buttonStyle(.tappableRowStyle)

					PlainListRow(title: "Factor Sources") {
						viewStore.send(.factorSourcesButtonTapped)
					} icon: {
						Image(systemName: "person.badge.key")
							.frame(.verySmall)
					}
					.withSeparator
					.buttonStyle(.tappableRowStyle)

					PlainListRow(title: "Import from a Legacy Wallet") {
						viewStore.send(.importFromOlympiaWalletButtonTapped)
					} icon: {
						Image(asset: AssetResource.appSettings)
					}
					.withSeparator
					.buttonStyle(.tappableRowStyle)
					#endif

					ForEach(settingsRows()) { row in
						PlainListRow(title: row.title, asset: row.asset) {
							viewStore.send(row.action)
						}
						.withSeparator
						.buttonStyle(.tappableRowStyle)
					}
				}
				.padding(.bottom, .large3)
				VStack(spacing: .zero) {
					Button(L10n.Settings.deleteAllButtonTitle) {
						viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(isDestructive: true))
					.padding(.bottom, .large1)

					Text(viewStore.appVersion)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.padding(.bottom, .medium1)
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
