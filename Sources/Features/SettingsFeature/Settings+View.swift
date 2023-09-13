import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import LedgerHardwareDevicesFeature
import P2PLinksFeature
import ProfileBackupsFeature
#if DEBUG
import DebugInspectProfileFeature
import EngineKit
import RadixConnectModels // read signaling client url
import SecureStorageClient
import SecurityStructureConfigurationListFeature
#endif

// MARK: - Settings.View
extension Settings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		#if DEBUG
		let debugAppInfo: String
		#endif
		let shouldShowAddP2PLinkButton: Bool
		let shouldShowMigrateOlympiaButton: Bool
		let appVersion: String

		var showsSomeBanner: Bool {
			shouldShowAddP2PLinkButton || shouldShowMigrateOlympiaButton
		}

		init(state: Settings.State) {
			#if DEBUG
			let retCommitHash: String = buildInformation().version
			self.debugAppInfo = "RET #\(retCommitHash), SS \(RadixConnectConstants.defaultSignalingServer.absoluteString)"
			#endif

			self.shouldShowAddP2PLinkButton = state.userHasNoP2PLinks ?? false
			self.shouldShowMigrateOlympiaButton = state.shouldShowMigrateOlympiaButton
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.appVersion(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

// MARK: - SettingsRowModel
struct SettingsRowModel<Feature: FeatureReducer>: Identifiable {
	var id: String { title }

	let title: String
	var subtitle: String?
	let icon: AssetIcon.Content
	let action: Feature.ViewAction
}

// MARK: - SettingsRow
struct SettingsRow<Feature: FeatureReducer>: View {
	let row: SettingsRowModel<Feature>
	let action: () -> Void

	var body: some View {
		PlainListRow(row.icon, title: row.title, subtitle: row.subtitle)
			.tappable(action)
			.withSeparator
	}
}

extension Settings.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
			settingsView(viewStore: viewStore)
				.navigationTitle(L10n.Settings.title)
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.navigationDestinations(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}
}

// MARK: - Extensions

extension Settings.State {
	var viewState: Settings.ViewState {
		.init(state: self)
	}
}

extension Settings.View {
	@MainActor
	private func settingsView(viewStore: ViewStoreOf<Settings>) -> some View {
		ScrollView {
			VStack(spacing: .zero) {
				if viewStore.showsSomeBanner {
					VStack(spacing: .medium3) {
						if viewStore.shouldShowAddP2PLinkButton {
							ConnectExtensionView {
								viewStore.send(.addP2PLinkButtonTapped)
							}
						}
						if viewStore.shouldShowMigrateOlympiaButton {
							MigrateOlympiaAccountsView {
								viewStore.send(.importOlympiaButtonTapped)
							} dismiss: {
								viewStore.send(.dismissImportOlympiaHeaderButtonTapped)
							}
							.transition(headerTransition)
						}
					}
					.padding(.medium3)
				}

				ForEach(rows) { row in
					SettingsRow(row: row) {
						viewStore.send(row.action)
					}
				}
			}
			.padding(.bottom, .large3)

			VStack(spacing: .zero) {
				Text(viewStore.appVersion)
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)
					.padding(.bottom, .medium1)

				#if DEBUG
				Text(viewStore.debugAppInfo)
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)
					.padding(.bottom, .medium1)
				#endif
			}
		}
		.animation(.default, value: viewStore.shouldShowMigrateOlympiaButton)
		.onAppear {
			viewStore.send(.appeared)
		}
	}

	private var headerTransition: AnyTransition {
		.scale(scale: 0.8).combined(with: .opacity)
	}

	@MainActor
	private var rows: [SettingsRowModel<Settings>] {
		var visibleRows = normalRows
		#if DEBUG
		visibleRows.append(.init(
			title: "Debug Settings",
			icon: .asset(AssetResource.appSettings), // FIXME: Find
			action: .debugButtonTapped
		))
		#endif
		return visibleRows
	}

	@MainActor
	private var normalRows: [SettingsRowModel<Settings>] {
		[
			.init(
				title: L10n.Settings.authorizedDapps,
				icon: .asset(AssetResource.authorizedDapps),
				action: .authorizedDappsButtonTapped
			),
			.init(
				title: L10n.Settings.personas,
				icon: .asset(AssetResource.personas),
				action: .personasButtonTapped
			),
			.init(
				title: L10n.Settings.accountSecurityAndSettings,
				icon: .asset(AssetResource.accountSecurity),
				action: .accountSecurityButtonTapped
			),
			.init(
				title: L10n.Settings.appSettings,
				icon: .asset(AssetResource.appSettings),
				action: .appSettingsButtonTapped
			),
		]
	}
}

extension View {
	@MainActor
	fileprivate func navigationDestinations(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		self
			.manageP2PLinks(with: destinationStore)
			.authorizedDapps(with: destinationStore)
			.personas(with: destinationStore)
			.accountSecurity(with: destinationStore)
			.appSettings(with: destinationStore)
		#if DEBUG
			.debugSettings(with: destinationStore)
		#endif
	}

	@MainActor
	private func manageP2PLinks(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.manageP2PLinks,
			action: Settings.Destinations.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	@MainActor
	private func authorizedDapps(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.authorizedDapps,
			action: Settings.Destinations.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	@MainActor
	private func personas(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.personas,
			action: Settings.Destinations.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func accountSecurity(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.accountSecurity,
			action: Settings.Destinations.Action.accountSecurity,
			destination: { AccountSecurity.View(store: $0) }
		)
	}

	@MainActor
	private func appSettings(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.appSettings,
			action: Settings.Destinations.Action.appSettings,
			destination: { AppSettings.View(store: $0) }
		)
	}

	#if DEBUG
	@MainActor
	private func debugSettings(with destinationStore: PresentationStoreOf<Settings.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destinations.State.debugSettings,
			action: Settings.Destinations.Action.debugSettings,
			destination: { DebugSettingsCoordinator.View(store: $0) }
		)
	}
	#endif
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		Settings.View(
			store: .init(
				initialState: .init(),
				reducer: Settings.init
			)
		)
	}
}
#endif

// MARK: - ConnectExtensionView
struct ConnectExtensionView: View {
	let action: () -> Void

	var body: some View {
		VStack(spacing: .medium2) {
			Image(asset: AssetResource.browsers)
				.padding(.horizontal, .medium1)

			Text(L10n.Settings.LinkToConnectorHeader.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .medium2)

			Text(L10n.Settings.LinkToConnectorHeader.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .medium2)

			Button(L10n.Settings.LinkToConnectorHeader.linkToConnector, action: action)
				.buttonStyle(.secondaryRectangular(
					shouldExpand: true,
					image: .init(asset: AssetResource.qrCodeScanner)
				))
				.padding(.horizontal, .medium1)
		}
		.padding(.vertical, .medium1)
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
	}
}

// MARK: - MigrateOlympiaAccountsView
struct MigrateOlympiaAccountsView: View {
	let action: () -> Void
	let dismiss: () -> Void

	var body: some View {
		VStack(spacing: .medium2) {
			Text(L10n.Settings.ImportFromLegacyWalletHeader.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .medium2)

			Text(L10n.Settings.ImportFromLegacyWalletHeader.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .medium1)

			Button(
				L10n.Settings.ImportFromLegacyWalletHeader.importLegacyAccounts,
				action: action
			)
			.buttonStyle(.secondaryRectangular(
				shouldExpand: true,
				image: .init(asset: AssetResource.qrCodeScanner) // FIXME: Pick asset
			))
			.padding(.horizontal, .medium1)
		}
		.padding(.vertical, .medium1)
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
		.overlay(alignment: .topTrailing) {
			CloseButton(action: dismiss)
				.offset(x: .small3, y: -.small3)
		}
	}
}
