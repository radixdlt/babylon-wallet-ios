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

extension AppSettings.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			NavigationStack {
				settingsView(viewStore: viewStore)
				#if os(iOS)
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
				#endif
					.navigationTitle(L10n.Settings.title)
					.navigationDestination(store: store.manageP2PClients) { store in
						ManageP2PClients.View(store: store)
					}
					.navigationDestination(store: store.manageGatewayAPIEndpoints) { store in
						ManageGatewayAPIEndpoints.View(store: store)
					}
					.navigationDestination(store: store.connectedDapps) { store in
						ConnectedDapps.View(store: store)
					}
					.navigationDestination(store: store.personasCoordinator) { store in
						PersonasCoordinator.View(store: store)
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

private extension AppSettings.Store {
	var manageP2PClients: PresentationStoreOf<ManageP2PClients> {
		scope(state: \.$manageP2PClients) { .child(.manageP2PClients($0)) }
	}

	var manageGatewayAPIEndpoints: PresentationStoreOf<ManageGatewayAPIEndpoints> {
		scope(state: \.$manageGatewayAPIEndpoints) { .child(.manageGatewayAPIEndpoints($0)) }
	}

	var connectedDapps: PresentationStoreOf<ConnectedDapps> {
		scope(state: \.$connectedDapps) { .child(.connectedDapps($0)) }
	}

	var personasCoordinator: PresentationStoreOf<PersonasCoordinator> {
		scope(state: \.$personasCoordinator) { .child(.personasCoordinator($0)) }
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
		 .init(title: L10n.Settings.connectedDappsButtonTitle,
		       asset: AssetResource.connectedDapps,
		       action: .connectedDappsButtonTapped),
		 .init(title: L10n.Settings.personasButtonTitle,
		       asset: AssetResource.personas,
		       action: .personasButtonTapped)]
	}

	private func settingsView(viewStore: ViewStore<AppSettings.ViewState, AppSettings.ViewAction>) -> some View {
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
