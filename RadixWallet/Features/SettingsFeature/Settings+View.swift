import ComposableArchitecture
import SwiftUI

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
		let appVersion: String

		init(state: Settings.State) {
			#if DEBUG
			let buildInfo = SargonBuildInformation.get()
			let dependencies = buildInfo.dependencies
			let sargon = buildInfo.sargonVersion.description
			let ret = String(dependencies.radixEngineToolkit.description.prefix(7))
			self.debugAppInfo =
				"""
				Sargon: \(sargon)
				RET: #\(ret)
				SS: \(RadixConnectConstants.defaultSignalingServer.absoluteString)
				"""
			#endif

			self.shouldShowAddP2PLinkButton = state.userHasNoP2PLinks ?? false
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.WalletSettings.appVersion(bundleInfo.shortVersion)
		}
	}
}

extension Settings.View {
	public var body: some View {
		settingsView()
			.setUpNavigationBar(title: L10n.WalletSettings.title)
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
			.destinations(with: store)
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
	private func settingsView() -> some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					if viewStore.shouldShowAddP2PLinkButton {
						ConnectExtensionView {
							viewStore.send(.addConnectorButtonTapped)
						}
					}

					ForEach(rows) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}

				VStack(spacing: .medium1) {
					Text(viewStore.appVersion)
						.foregroundColor(.app.gray2)
						.textStyle(.body1Regular)

					#if DEBUG
					Text(viewStore.debugAppInfo)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.multilineTextAlignment(.leading)
					#endif
				}
				.frame(minHeight: .huge1)
			}
			.background(Color.app.gray4)
			.onAppear {
				store.send(.view(.appeared))
			}
		}
	}

	private var headerTransition: AnyTransition {
		.scale(scale: 0.8).combined(with: .opacity)
	}

	@MainActor
	private var rows: [SettingsRow<Settings>.Kind] {
		var visibleRows = normalRows
		#if DEBUG
		visibleRows.append(.separator)
		visibleRows.append(.model(
			title: "Debug Settings",
			icon: .asset(AssetResource.appSettings), // FIXME: Find
			action: .debugButtonTapped
		))
		#endif
		return visibleRows
	}

	@MainActor
	private var normalRows: [SettingsRow<Settings>.Kind] {
		[
			.model(
				title: L10n.WalletSettings.SecurityCenter.title,
				subtitle: L10n.WalletSettings.SecurityCenter.subtitle,
				icon: .asset(AssetResource.security),
				action: .securityButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Personas.title,
				subtitle: L10n.WalletSettings.Personas.subtitle,
				icon: .asset(AssetResource.personas),
				action: .personasButtonTapped
			),
			.model(
				title: L10n.WalletSettings.Dapps.title,
				subtitle: L10n.WalletSettings.Dapps.subtitle,
				icon: .asset(AssetResource.authorizedDapps),
				action: .dappsButtonTapped
			),
			.model(
				title: L10n.WalletSettings.Connectors.title,
				subtitle: L10n.WalletSettings.Connectors.subtitle,
				icon: .asset(AssetResource.desktopConnections),
				action: .connectorsButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Preferences.title,
				subtitle: L10n.WalletSettings.Preferences.subtitle,
				icon: .asset(AssetResource.depositGuarantees),
				action: .preferencesButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Troubleshooting.title,
				subtitle: L10n.WalletSettings.Troubleshooting.subtitle,
				icon: .asset(AssetResource.troubleshooting),
				action: .troubleshootingButtonTapped
			),
		]
	}
}

private extension StoreOf<Settings> {
	var destination: PresentationStoreOf<Settings.Destination> {
		func scopeState(state: State) -> PresentationState<Settings.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Settings>) -> some View {
		let destinationStore = store.destination
		return manageP2PLinks(with: destinationStore)
			.authorizedDapps(with: destinationStore)
			.personas(with: destinationStore)
			.preferences(with: destinationStore)
			.troubleshooting(with: destinationStore)
		#if DEBUG
			.debugSettings(with: destinationStore)
		#endif
	}

	private func manageP2PLinks(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.manageP2PLinks,
			action: Settings.Destination.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	private func authorizedDapps(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.authorizedDapps,
			action: Settings.Destination.Action.authorizedDapps,
			destination: { AuthorizedDapps.View(store: $0) }
		)
	}

	private func personas(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.personas,
			action: Settings.Destination.Action.personas,
			destination: { PersonasCoordinator.View(store: $0) }
		)
	}

	private func preferences(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.preferences,
			action: Settings.Destination.Action.preferences,
			destination: { Preferences.View(store: $0) }
		)
	}

	private func troubleshooting(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.troubleshooting,
			action: Settings.Destination.Action.troubleshooting,
			destination: { Troubleshooting.View(store: $0) }
		)
	}

	#if DEBUG
	private func debugSettings(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.debugSettings,
			action: Settings.Destination.Action.debugSettings,
			destination: { DebugSettingsCoordinator.View(store: $0) }
		)
	}
	#endif
}

// MARK: - Settings.View.ConnectExtensionView
extension Settings.View {
	// MARK: - ConnectExtensionView
	struct ConnectExtensionView: View {
		let action: () -> Void

		var body: some View {
			VStack(spacing: .medium2) {
				Image(asset: AssetResource.connectorBrowsersIcon)

				VStack(spacing: .medium3) {
					Text(L10n.WalletSettings.LinkToConnectorHeader.title)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)

					Text(L10n.WalletSettings.LinkToConnectorHeader.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.multilineTextAlignment(.center)
						.padding(.horizontal, .large3)
				}

				Button(L10n.WalletSettings.LinkToConnectorHeader.button, action: action)
					.buttonStyle(.secondaryRectangular(
						backgroundColor: .app.gray3,
						shouldExpand: true,
						image: .init(asset: AssetResource.qrCodeScanner)
					))
			}
			.padding(.vertical, .large3)
			.padding(.horizontal, .large2)
			.background(Color.clear)
		}
	}
}
