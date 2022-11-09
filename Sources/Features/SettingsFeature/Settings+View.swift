import ComposableArchitecture
import DesignSystem
import GatewayAPI
import KeychainClientDependency
import ManageBrowserExtensionConnectionsFeature
import Profile
import ProfileClient
import SwiftUI
#if DEBUG
import ProfileView
#endif // DEBUG

// MARK: - Settings.View
public extension Settings {
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
			send: Settings.Action.init
		) { viewStore in
			ForceFullScreen {
				ZStack {
					settingsView(viewStore: viewStore)
						.zIndex(0)
					IfLetStore(
						store.scope(
							state: \.manageBrowserExtensionConnections,
							action: { .child(.manageBrowserExtensionConnections($0)) }
						),
						then: ManageBrowserExtensionConnections.View.init(store:)
					)
					.zIndex(1)
				}
			}
			.buttonStyle(.borderedProminent)
			.onAppear {
				viewStore.send(.viewDidAppear)
			}
		}
	}
}

private extension Settings.View {
	func settingsView(viewStore: ViewStore<ViewState, ViewAction>) -> some View {
		Screen(
			title: "Settings",
			navBarActionStyle: .close,
			action: { viewStore.send(.dismissSettingsButtonTapped) }
		) {
			VStack {
				#if DEBUG
				Button("Debug Inspect Profile") {
					viewStore.send(.debugInspectProfileButtonTapped)
				}
				#endif // DEBUG

				Button(
					action: { viewStore.send(.browserExtensionConnectionsButtonTapped) },
					label: { Text("Browser Extension Connections") }
				)

				Spacer()
				Button("Delete Profile & Factor Sources", role: .destructive) {
					viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
				}

				Text("Version: \(Bundle.main.appVersionLong) build #\(Bundle.main.appBuild)")
			}
			#if DEBUG
				.sheet(isPresented: viewStore.binding(get: \.isDebugProfileViewSheetPresented, send: ViewAction.setDebugProfileSheet(isPresented:))) {
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
	}
}

// MARK: - Settings.View.ViewState
public extension Settings.View {
	struct ViewState: Equatable {
		#if DEBUG
		public let isDebugProfileViewSheetPresented: Bool
		public let profileToInspect: Profile?
		#endif // DEBUG
		public init(state: Settings.State) {
			#if DEBUG
			isDebugProfileViewSheetPresented = state.profileToInspect != nil
			profileToInspect = state.profileToInspect
			#endif // DEBUG
		}
	}
}

// MARK: - Settings.View.ViewAction
public extension Settings.View {
	enum ViewAction: Equatable {
		case dismissSettingsButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped
		case viewDidAppear
		case browserExtensionConnectionsButtonTapped
		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif // DEBUG
	}
}

extension Settings.Action {
	init(action: Settings.View.ViewAction) {
		switch action {
		case .dismissSettingsButtonTapped:
			self = .internal(.user(.dismissSettings))
		case .deleteProfileAndFactorSourcesButtonTapped:
			self = .internal(.user(.deleteProfileAndFactorSources))
		case .viewDidAppear:
			self = .internal(.system(.viewDidAppear))
		case .browserExtensionConnectionsButtonTapped:
			self = .internal(.user(.goToBrowserExtensionConnections))
		#if DEBUG
		case .debugInspectProfileButtonTapped:
			self = .internal(.user(.debugInspectProfile))
		case let .setDebugProfileSheet(isPresented):
			self = .internal(.user(.setDebugProfileSheet(isPresented: isPresented)))
		#endif // DEBUG
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
