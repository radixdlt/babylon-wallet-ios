import AuthorizedDAppsFeatures
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient
#if DEBUG
import ProfileView
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

	struct ViewState: Equatable {
		#if DEBUG
		let isDebugProfileViewSheetPresented: Bool
		let profileToInspect: Profile?
		#endif
		let shouldShowAddP2PClientButton: Bool
		let appVersion: String

		init(state: AppSettings.State) {
			#if DEBUG
			self.isDebugProfileViewSheetPresented = state.profileToInspect != nil
			self.profileToInspect = state.profileToInspect
			#endif
			self.shouldShowAddP2PClientButton = state.userHasNoP2PClients ?? false
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.versionInfo(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

extension AppSettings.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			NavigationStack {
				settingsView(viewStore: viewStore)
					.navigationTitle(L10n.Settings.title)
				#if os(iOS)
					.navigationBarBackButtonFont(.app.backButton)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						}
					}
					.navigationTransition(.default, interactivity: .pan)
				#endif
					.navigationDestinations(with: store, viewStore)
			}
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
		}
		.showDeveloperDisclaimerBanner()
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
		_ viewStore: ViewStore<AppSettings.ViewState, AppSettings.ViewAction>
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
			.navigationDestination(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AppSettings.Destinations.State.manageP2PClients,
				action: AppSettings.Destinations.Action.manageP2PClients,
				destination: { ManageP2PClients.View(store: $0) }
			)
			.navigationDestination(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AppSettings.Destinations.State.manageGatewayAPIEndpoints,
				action: AppSettings.Destinations.Action.manageGatewayAPIEndpoints,
				destination: { ManageGatewayAPIEndpoints.View(store: $0) }
			)
			.navigationDestination(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AppSettings.Destinations.State.authorizedDapps,
				action: AppSettings.Destinations.Action.authorizedDapps,
				destination: { AuthorizedDapps.View(store: $0) }
			)
			.navigationDestination(
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
		[.init(title: L10n.Settings.desktopConnectionsButtonTitle,
		       asset: AssetResource.desktopConnections,
		       action: .manageP2PClientsButtonTapped),
		 .init(title: L10n.Settings.gatewayButtonTitle,
		       asset: AssetResource.gateway,
		       action: .editGatewayAPIEndpointButtonTapped),
		 .init(title: L10n.Settings.authorizedDappsButtonTitle,
		       asset: AssetResource.authorizedDapps,
		       action: .authorizedDappsButtonTapped),
		 .init(title: L10n.Settings.personasButtonTitle,
		       asset: AssetResource.personas,
		       action: .personasButtonTapped),
		 .init(title: L10n.Settings.appSettingsButtonTitle,
		       asset: AssetResource.appSettings,
		       action: .appSettingsButtonTapped)]
	}

	private func settingsView(viewStore: ViewStore<AppSettings.ViewState, AppSettings.ViewAction>) -> some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(spacing: .zero) {
					if viewStore.shouldShowAddP2PClientButton {
						ConnectExtensionView {
							viewStore.send(.addP2PClientButtonTapped)
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
					.buttonStyle(.settingsRowStyle)
					#endif

					ForEach(settingsRows()) { row in
						PlainListRow(title: row.title, asset: row.asset) {
							viewStore.send(row.action)
						}
						.withSeparator
						.buttonStyle(.settingsRowStyle)
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
				viewStore.send(.didAppear)
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
