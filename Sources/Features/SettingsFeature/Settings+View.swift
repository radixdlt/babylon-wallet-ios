import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import ConnectedDAppsFeature
import PersonasFeature
import ProfileClient
#if DEBUG
import ProfileView
#endif

// MARK: - AppSettings.View
public extension AppSettings {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<AppSettings>
		private let store: Store

		public init(
			store: Store
		) {
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
							state: \.connectedDApps,
							action: { .child(.connectedDApps($0)) }
						),
						then: { ConnectedDApps.View(store: $0) }
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
		}
	}
}

private extension AppSettings.View {
	func settingsView(viewStore: ViewStore<ViewState, AppSettings.Action.ViewAction>) -> some View {
		ForceFullScreen {
			VStack(spacing: 0) {
				NavigationBar(
					titleText: L10n.Settings.title,
					leadingItem: BackButton {
						viewStore.send(.dismissSettingsButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .small2)
				.frame(height: .navBarHeight)
				ScrollView {
					VStack(spacing: .zero) {
						if viewStore.canAddP2PClient {
							ConnectExtensionView {
								viewStore.send(.addP2PClientButtonTapped)
							}
							.padding([.vertical], .medium3)
						}
						
						#if DEBUG
						PlainListRow(
							L10n.Settings.inspectProfileButtonTitle,
							icon: Image(systemName: "wallet.pass")
						) {
							viewStore.send(.debugInspectProfileButtonTapped)
						}
						#endif

						PlainListRow(
							L10n.Settings.desktopConnectionsButtonTitle,
							asset: AssetResource.desktopConnections
						) {
							viewStore.send(.manageP2PClientsButtonTapped)
						}
												
						PlainListRow(
							L10n.Settings.connectedDAppsButtonTitle,
							asset: AssetResource.connectedDapps
						) {
							viewStore.send(.connectedDAppsButtonTapped)
						}
						
						PlainListRow(
							L10n.Settings.gatewayButtonTitle,
							asset: AssetResource.gateway
						) {
							viewStore.send(.editGatewayAPIEndpointButtonTapped)
						}
						
						PlainListRow(
							L10n.Settings.personasButtonTitle,
							asset: AssetResource.personas
						) {
							viewStore.send(.personasButtonTapped)
						}
					}
					.buttonStyle(.settingsRowStyle)
					.padding(.horizontal, .medium3)
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
