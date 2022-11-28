import Common
import ComposableArchitecture
import DesignSystem
import GatewayAPI
import KeychainClientDependency
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import Profile
import ProfileClient
import SwiftUI
#if DEBUG
import ProfileView
#endif // DEBUG

// MARK: - Settings.View
public extension Settings {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<Settings>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Settings.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					settingsView(viewStore: viewStore)
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.manageP2PClients,
							action: { .child(.manageP2PClients($0)) }
						),
						then: ManageP2PClients.View.init(store:)
					)
					.zIndex(1)

					IfLetStore(
						store.scope(
							state: \.manageGatewayAPIEndpoints,
							action: { .child(.manageGatewayAPIEndpoints($0)) }
						),
						then: ManageGatewayAPIEndpoints.View.init(store:)
					)
					.zIndex(2)
				}
			}
		}
	}
}

private extension Settings.View {
	func settingsView(viewStore: ViewStore<ViewState, Settings.Action.ViewAction>) -> some View {
		ForceFullScreen {
			VStack {
				NavigationBar(
					titleText: L10n.Settings.title,
					leadingItem: CloseButton {
						viewStore.send(.dismissSettingsButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				Form {
					#if DEBUG
					Section(header: Text(L10n.Settings.Section.debug)) {
						Button(L10n.Settings.inspectProfileButtonTitle) {
							viewStore.send(.debugInspectProfileButtonTapped)
						}
						.buttonStyle(.primaryText())
					}
					#endif // DEBUG
					Section(header: Text(L10n.Settings.Section.p2Pconnections)) {
						Button(L10n.Settings.manageConnectionsButtonTitle) {
							viewStore.send(.manageP2PClientsButtonTapped)
						}
						.buttonStyle(.primaryText())

						if viewStore.canAddP2PClient {
							Button(L10n.Settings.addConnectionButtonTitle) {
								viewStore.send(.addP2PClientButtonTapped)
							}
							.buttonStyle(.primaryText())
						}
					}

					Section {
						Button(L10n.Settings.editGatewayAPIEndpointButtonTitle) {
							viewStore.send(.editGatewayAPIEndpointButtonTapped)
						}
						.buttonStyle(.primaryText())
					}

					Section {
						Button(L10n.Settings.deleteAllButtonTitle) {
							viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
						}
						.buttonStyle(.primaryText(isDestructive: true))
					} footer: {
						Text(L10n.Settings.versionInfo(Bundle.main.appVersionLong, Bundle.main.appBuild))
							.textStyle(.body2Regular)
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
				#endif // DEBUG
			}
		}
	}
}

// MARK: - Settings.View.ViewState
public extension Settings.View {
	struct ViewState: Equatable {
		#if DEBUG
		public let isDebugProfileViewSheetPresented: Bool
		public let profileToInspect: Profile?
		#endif // DEBUG
		public let canAddP2PClient: Bool
		public init(state: Settings.State) {
			#if DEBUG
			isDebugProfileViewSheetPresented = state.profileToInspect != nil
			profileToInspect = state.profileToInspect
			#endif // DEBUG
			canAddP2PClient = state.canAddP2PClient
		}
	}
}

// MARK: - HomeView_Previews
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Settings.View(
			store: .init(
				initialState: .init(),
				reducer: Settings()
			)
		)
	}
}
