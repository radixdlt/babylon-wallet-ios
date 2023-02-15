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
extension AppSettings {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		#if DEBUG
		let isDebugProfileViewSheetPresented: Bool
		let profileToInspect: Profile?
		#endif
		let canAddP2PClient: Bool
		let appVersion: String

		init(state: AppSettings.State) {
			#if DEBUG
			self.isDebugProfileViewSheetPresented = state.profileToInspect != nil
			self.profileToInspect = state.profileToInspect
			#endif
			self.canAddP2PClient = state.canAddP2PClient
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.versionInfo(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

public extension AppSettings.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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

// MARK: - Extensions

extension AppSettings.State {
	var viewState: AppSettings.ViewState {
		.init(state: self)
	}
}

extension AppSettings.Store {
	var connectedDApps: PresentationStoreOf<ConnectedDApps> {
		scope(state: \.$connectedDApps) { .child(.connectedDApps($0)) }
	}
}

// MARK: - SettingsRowModel

extension AppSettings.View {
	struct RowModel: Identifiable {
		var id: String { title }
		let title: String
		let asset: ImageAsset
		let action: AppSettings.Action.ViewAction
	}

	private func settingsRows() -> [RowModel] {
		[
			.init(title: L10n.Settings.inspectProfileButtonTitle,
			      asset: AssetResource.desktopConnections,
			      action: .manageP2PClientsButtonTapped),
			.init(title: L10n.Settings.connectedDAppsButtonTitle,
			      asset: AssetResource.connectedDapps,
			      action: .connectedDAppsButtonTapped),
			.init(title: L10n.Settings.gatewayButtonTitle,
			      asset: AssetResource.gateway,
			      action: .editGatewayAPIEndpointButtonTapped),
			.init(title: L10n.Settings.personasButtonTitle,
			      asset: AssetResource.personas,
			      action: .personasButtonTapped),
		]
	}

	private func settingsView(viewStore: ViewStore<AppSettings.ViewState, AppSettings.Action.ViewAction>) -> some View {
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
