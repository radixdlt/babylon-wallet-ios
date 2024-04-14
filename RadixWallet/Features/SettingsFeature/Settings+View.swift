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
		let shouldShowMigrateOlympiaButton: Bool
		let shouldWriteDownPersonasSeedPhrase: Bool
		let appVersion: String

		var showsSomeBanner: Bool {
			shouldShowAddP2PLinkButton || shouldShowMigrateOlympiaButton
		}

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
			self.shouldShowMigrateOlympiaButton = state.shouldShowMigrateOlympiaButton
			self.shouldWriteDownPersonasSeedPhrase = state.shouldWriteDownPersonasSeedPhrase
			@Dependency(\.bundleInfo) var bundleInfo: BundleInfo
			self.appVersion = L10n.Settings.appVersion(bundleInfo.shortVersion, bundleInfo.version)
		}
	}
}

// MARK: - SettingsRowModel
struct SettingsRowModel<Feature: FeatureReducer>: Identifiable {
	let id: String
	let rowViewState: PlainListRow<AssetIcon>.ViewState
	let action: Feature.ViewAction

	public init(
		title: String,
		subtitle: String? = nil,
		hint: Hint.ViewState? = nil,
		icon: AssetIcon.Content,
		action: Feature.ViewAction
	) {
		self.id = title
		self.rowViewState = .init(icon, rowCoreViewState: .init(title: title, subtitle: subtitle, hint: hint))
		self.action = action
	}
}

// MARK: - SettingsRow
struct SettingsRow<Feature: FeatureReducer>: View {
	let row: SettingsRowModel<Feature>
	let action: () -> Void

	var body: some View {
		VStack(spacing: .small3) {
			PlainListRow(viewState: row.rowViewState)
				.tappable(action)
				.withSeparator
		}
	}
}

extension Settings.View {
	public var body: some View {
		settingsView()
			.navigationTitle(L10n.Settings.title)
			.navigationBarTitleColor(.app.gray1)
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarInlineTitleFont(.app.secondaryHeader)
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

					ForEach(rows(viewStore: viewStore)) { row in
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
						.multilineTextAlignment(.leading)
					#endif
				}
			}
			.animation(.default, value: viewStore.shouldShowMigrateOlympiaButton)
			.onAppear {
				store.send(.view(.appeared))
			}
		}
	}

	private var headerTransition: AnyTransition {
		.scale(scale: 0.8).combined(with: .opacity)
	}

	@MainActor
	private func rows(viewStore: ViewStoreOf<Settings>) -> [SettingsRowModel<Settings>] {
		var visibleRows = normalRows(viewStore: viewStore)
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
	private func normalRows(viewStore: ViewStoreOf<Settings>) -> [SettingsRowModel<Settings>] {
		[
			.init(
				title: L10n.Settings.authorizedDapps,
				icon: .asset(AssetResource.authorizedDapps),
				action: .authorizedDappsButtonTapped
			),
			.init(
				title: L10n.Settings.personas,
				hint: viewStore.shouldWriteDownPersonasSeedPhrase ? .init(kind: .warning, text: .init(L10n.Settings.personasSeedPhrasePrompt)) : nil,
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
			.accountSecurity(with: destinationStore)
			.appSettings(with: destinationStore)
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
			destination: { AuthorizedDappsReducer.View(store: $0) }
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

	private func accountSecurity(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.accountSecurity,
			action: Settings.Destination.Action.accountSecurity,
			destination: { AccountSecurity.View(store: $0) }
		)
	}

	private func appSettings(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Settings.Destination.State.appSettings,
			action: Settings.Destination.Action.appSettings,
			destination: { AppSettings.View(store: $0) }
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

#if DEBUG
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
			Image(asset: AssetResource.connectorBrowsersIcon)
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
				.padding(.small3)
		}
	}
}
