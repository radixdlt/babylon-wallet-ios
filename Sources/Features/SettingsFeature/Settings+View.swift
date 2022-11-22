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
			.buttonStyle(.borderedProminent)
		}
	}
}

private extension Settings.View {
	func settingsView(viewStore: ViewStore<ViewState, Settings.Action.ViewAction>) -> some View {
		Screen(
			title: "Settings",
			navBarActionStyle: .close,
			action: { viewStore.send(.dismissSettingsButtonTapped) }
		) {
			Form {
				#if DEBUG
				Section(header: Text("Debug")) {
					Button("Inspect Profile") {
						viewStore.send(.debugInspectProfileButtonTapped)
					}
				}
				#endif // DEBUG
				Section(header: Text("P2P Connections")) {
					Button("Manage Connections") {
						viewStore.send(.manageP2PClientsButtonTapped)
					}

					if viewStore.canAddP2PClient {
						Button("Add Connection") {
							viewStore.send(.addP2PClientButtonTapped)
						}
					}
				}

				Section {
					Button("Edit Gateway API Endpoint") {
						viewStore.send(.editGatewayAPIEndpointButtonTapped)
					}
				}

				Section {
					Button("Delete all  & Factor Sources", role: .destructive) {
						viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
					}

					Text("Version: \(Bundle.main.appVersionLong) build #\(Bundle.main.appBuild)")
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
						Button("Close") {
							viewStore.send(.setDebugProfileSheet(isPresented: false))
						}
						if let profile = viewStore.profileToInspect {
							ProfileView(
								profile: profile,
								// Sorry about this, hacky hacky hack. But it is only for debugging and we are short on time..
								keychainClient: KeychainClient.liveValue
							)
						} else {
							Text("No profile, strange")
						}
					}
				}
			#endif // DEBUG
		}
		.buttonStyle(.borderless)
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

public extension Bundle {
	var appName: String { getInfo("CFBundleName") }
	var displayName: String { getInfo("CFBundleDisplayName") }
	var language: String { getInfo("CFBundleDevelopmentRegion") }
	var identifier: String { getInfo("CFBundleIdentifier") }
	var copyright: String { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

	var appBuild: String { getInfo("CFBundleVersion") }
	var appVersionLong: String { getInfo("CFBundleShortVersionString") }

	private func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
