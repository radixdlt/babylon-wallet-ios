import ConnectedDAppsFeature
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
		public typealias Store = ComposableArchitecture.StoreOf<AppSettings>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

extension AppSettings.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			NavigationStack {
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
				.navigationDestination(store: store.connectedDapps) { store in
					ConnectedDapps.View(store: store)
				}
			}
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
			.textStyle(.secondaryHeader)
		}
	}
}

extension StoreOf<AppSettings> {
	var connectedDapps: PresentationStoreOf<ConnectedDapps> {
		scope(state: \.$connectedDapps) { .child(.connectedDapps($0)) }
	}
}

extension AppSettings.View {
	fileprivate func settingsView(viewStore: ViewStore<ViewState, AppSettings.Action.ViewAction>) -> some View {
		ForceFullScreen {
			VStack {
				NavigationBar(
					titleText: L10n.Settings.title,
					leadingItem: BackButton {
						viewStore.send(.dismissSettingsButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				ScrollView {
					VStack(spacing: .zero) {
						if viewStore.canAddP2PClient {
							ConnectExtensionView {
								viewStore.send(.addP2PClientButtonTapped)
							}
							Spacer()
								.frame(height: .medium3)
						}

						#if DEBUG
						Row(
							L10n.Settings.inspectProfileButtonTitle,
							icon: Image(systemName: "wallet.pass")
						) {
							viewStore.send(.debugInspectProfileButtonTapped)
						}
						#endif

						Row(
							L10n.Settings.desktopConnectionsButtonTitle,
							icon: Image(asset: AssetResource.desktopConnections)
						) {
							viewStore.send(.manageP2PClientsButtonTapped)
						}

						Row(
							L10n.Settings.gatewayButtonTitle,
							icon: Image(asset: AssetResource.gateway)
						) {
							viewStore.send(.editGatewayAPIEndpointButtonTapped)
						}

						Row(
							L10n.Settings.connectedDappsButtonTitle,
							icon: Image(asset: AssetResource.connectedDapps)
						) {
							viewStore.send(.connectedDappsButtonTapped)
						}

						Row(
							L10n.Settings.personasButtonTitle,
							icon: Image(asset: AssetResource.personas)
						) {
							viewStore.send(.personasButtonTapped)
						}
					}
					VStack(spacing: .zero) {
						Spacer()
							.frame(height: .large3)

						Button(L10n.Settings.deleteAllButtonTitle) {
							viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(isDestructive: true))

						Spacer()
							.frame(height: .large1)

						Text(viewStore.appVersion)
							.foregroundColor(.app.gray2)
							.textStyle(.body2Regular)

						Spacer()
							.frame(height: .medium1)
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
									secureStorageClient: SecureStorageClient.liveValue
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
extension AppSettings.View {
	public struct ViewState: Equatable {
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
