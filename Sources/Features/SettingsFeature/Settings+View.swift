import ConnectedDAppsFeature
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient
#if DEBUG
import ProfileView
#endif

// MARK: - AppSettings.View
public extension AppSettings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension AppSettings.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			NavigationStack {
				ForceFullScreen {
					ZStack {
						settingsView(viewStore: viewStore)

						IfLetStore(
							store.scope(
								state: \.manageP2PClients,
								action: { .child(.manageP2PClients($0)) }
							),
							then: { ManageP2PClients.View(store: $0) }
						)

						IfLetStore(
							store.scope(
								state: \.manageGatewayAPIEndpoints,
								action: { .child(.manageGatewayAPIEndpoints($0)) }
							),
							then: { ManageGatewayAPIEndpoints.View(store: $0) }
						)

						IfLetStore(
							store.scope(
								state: \.personasCoordinator,
								action: { .child(.personasCoordinator($0)) }
							),
							then: { PersonasCoordinator.View(store: $0) }
						)
					}
				}
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						BackButton {
							viewStore.send(.dismissSettingsButtonTapped)
						}
					}
					ToolbarItem(placement: .principal) {
						Text(L10n.Settings.title)
					}
				}
				.navigationTitle(L10n.Settings.title)
				.navigationDestination(store: store.connectedDApps) { store in
					ConnectedDApps.View(store: store)
				}
			}
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
			.textStyle(.secondaryHeader)
		}
	}
}

extension AppSettings.Store {
	var connectedDApps: PresentationStoreOf<ConnectedDApps> {
		scope(state: \.$connectedDApps) { .child(.connectedDApps($0)) }
	}
}

private extension AppSettings.View {
	func settingsView(viewStore: ViewStore<ViewState, AppSettings.Action.ViewAction>) -> some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(spacing: .zero) {
					if viewStore.canAddP2PClient {
						ConnectExtensionView {
							viewStore.send(.addP2PClientButtonTapped)
						}
						.padding(.medium3)
					}

					#if DEBUG
					PlainListRow(
						title: L10n.Settings.inspectProfileButtonTitle
					) {
						viewStore.send(.debugInspectProfileButtonTapped)
					} icon: {
						Image(systemName: "wallet.pass")
					}
					.withSeparator
					#endif

					PlainListRow(
						title: L10n.Settings.desktopConnectionsButtonTitle,
						asset: AssetResource.desktopConnections
					) {
						viewStore.send(.manageP2PClientsButtonTapped)
					}
					.withSeparator

					PlainListRow(
						title: L10n.Settings.connectedDAppsButtonTitle,
						asset: AssetResource.connectedDapps
					) {
						viewStore.send(.connectedDAppsButtonTapped)
					}
					.withSeparator

					PlainListRow(
						title: L10n.Settings.gatewayButtonTitle,
						asset: AssetResource.gateway
					) {
						viewStore.send(.editGatewayAPIEndpointButtonTapped)
					}
					.withSeparator

					PlainListRow(
						title: L10n.Settings.personasButtonTitle,
						asset: AssetResource.personas
					) {
						viewStore.send(.personasButtonTapped)
					}
					.withSeparator
				}
				.buttonStyle(.settingsRowStyle)
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
			#if DEBUG
				.sheet(
					isPresented: viewStore.binding(
						get: \.isDebugProfileViewSheetPresented,
						send: { .setDebugProfileSheet(isPresented: $0) }
					)
				) {
					VStack {
						Button(L10n.Settings.closeButtonTitle) {
							viewStore.send(.setDebugProfileSheet(isPresented: false))
						}
						if let profile = viewStore.profileToInspect {
							ProfileView(
								profile: profile,
								// Sorry about this, hacky hacky hack. But it is only for debugging and we are short on time..
								keychainClient: KeychainClient.liveValue
							)
						} else {
							Text(L10n.Settings.noProfileText)
						}
					}
				}
			#endif
		}
	}
}

// MARK: - AppSettings.View.ViewState
public extension AppSettings.View {
	struct ViewState: Equatable {
		#if DEBUG
		public let isDebugProfileViewSheetPresented: Bool
		public let profileToInspect: Profile?
		#endif
		public let canAddP2PClient: Bool
		public let appVersion: String

		public init(state: AppSettings.State) {
			#if DEBUG
			isDebugProfileViewSheetPresented = state.profileToInspect != nil
			profileToInspect = state.profileToInspect
			#endif
			canAddP2PClient = state.canAddP2PClient
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			appVersion = L10n.Settings.versionInfo(bundleInfo.shortVersion, bundleInfo.version)
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
