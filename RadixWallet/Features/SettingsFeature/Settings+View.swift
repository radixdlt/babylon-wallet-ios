import ComposableArchitecture
import SwiftUI

// MARK: - Settings.View
extension Settings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		#if DEBUG
		let debugAppInfo: String
		#endif
		let securityProblems: [SecurityProblem]
		let personasSecurityProblems: [SecurityProblem]
		let appVersion: String

		init(state: Settings.State) {
			@Dependency(\.bundleInfo) var bundleInfo
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
			self.appVersion = L10n.WalletSettings.appVersion("\(bundleInfo.shortVersion) (\(bundleInfo.version))")
			#else
			self.appVersion = L10n.WalletSettings.appVersion(bundleInfo.shortVersion)
			#endif

			self.securityProblems = state.securityProblems
			self.personasSecurityProblems = state.personasSecurityProblems
		}
	}
}

extension Settings.View {
	var body: some View {
		VStack(spacing: .zero) {
			Text(L10n.WalletSettings.title)
				.foregroundColor(Color.primaryText)
				.background(.primaryBackground)
				.textStyle(.body1Header)
				.padding(.vertical, .small1)
			Separator()
			settingsView()
		}
		.background(.primaryBackground)
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
					ForEachStatic(rows(securityProblems: viewStore.securityProblems, personasProblems: viewStore.personasSecurityProblems)) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}

				VStack(spacing: .medium1) {
					Text(viewStore.appVersion)
						.foregroundColor(.secondaryText)
						.textStyle(.body1Regular)

					#if DEBUG
					Text(viewStore.debugAppInfo)
						.foregroundColor(.secondaryText)
						.textStyle(.body2Regular)
						.multilineTextAlignment(.leading)
					#endif
				}
				.frame(minHeight: .huge1)
			}
			.background(Color.secondaryBackground)
			.task {
				store.send(.view(.task))
			}
		}
	}

	private var headerTransition: AnyTransition {
		.scale(scale: 0.8).combined(with: .opacity)
	}

	@MainActor
	private func rows(securityProblems: [SecurityProblem], personasProblems: [SecurityProblem]) -> [SettingsRow<Settings>.Kind] {
		var visibleRows = normalRows(securityProblems: securityProblems, personasProblems: personasProblems)
		#if DEBUG
		visibleRows.append(.separator)
		visibleRows.append(.model(
			title: "Debug Settings",
			icon: .asset(.appSettings), // FIXME: Find
			action: .debugButtonTapped
		))
		#endif
		return visibleRows
	}

	@MainActor
	private func normalRows(securityProblems: [SecurityProblem], personasProblems: [SecurityProblem]) -> [SettingsRow<Settings>.Kind] {
		[
			.model(
				title: L10n.WalletSettings.SecurityCenter.title,
				subtitle: L10n.WalletSettings.SecurityCenter.subtitle,
				hints: securityCenterHints(problems: securityProblems),
				icon: .asset(.security),
				action: .securityCenterButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Personas.title,
				subtitle: L10n.WalletSettings.Personas.subtitle,
				hints: personasHints(problems: personasProblems),
				icon: .asset(.personas),
				action: .personasButtonTapped
			),
			.model(
				title: L10n.WalletSettings.Connectors.title,
				subtitle: L10n.WalletSettings.Connectors.subtitle,
				icon: .asset(.desktopConnections),
				action: .connectorsButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Preferences.title,
				subtitle: L10n.WalletSettings.Preferences.subtitle,
				icon: .asset(.depositGuarantees),
				action: .preferencesButtonTapped
			),
			.separator,
			.model(
				title: L10n.WalletSettings.Troubleshooting.title,
				subtitle: L10n.WalletSettings.Troubleshooting.subtitle,
				icon: .asset(.troubleshooting),
				action: .troubleshootingButtonTapped
			),
		]
	}

	@MainActor
	private func securityCenterHints(problems: [SecurityProblem]) -> [Hint.ViewState] {
		problems.map { problem in
			.init(kind: .warning, text: problem.walletSettingsSecurityCenter)
		}
	}

	@MainActor
	private func personasHints(problems: [SecurityProblem]) -> [Hint.ViewState] {
		problems.map { problem in
			.init(kind: .warning, text: problem.walletSettingsPersonas)
		}
	}
}

private extension StoreOf<Settings> {
	var destination: PresentationStoreOf<Settings.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Settings>) -> some View {
		let destinationStore = store.destination
		return securityCenter(with: destinationStore)
			.manageP2PLinks(with: destinationStore)
			.personas(with: destinationStore)
			.preferences(with: destinationStore)
			.troubleshooting(with: destinationStore)
		#if DEBUG
			.debugSettings(with: destinationStore)
		#endif
	}

	private func securityCenter(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.securityCenter, action: \.securityCenter)) {
			SecurityCenter.View(store: $0)
		}
	}

	private func manageP2PLinks(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.manageP2PLinks, action: \.manageP2PLinks)) {
			P2PLinksFeature.View(store: $0)
		}
	}

	private func personas(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.personas, action: \.personas)) {
			PersonasCoordinator.View(store: $0)
		}
	}

	private func preferences(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.preferences, action: \.preferences)) {
			Preferences.View(store: $0)
		}
	}

	private func troubleshooting(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.troubleshooting, action: \.troubleshooting)) {
			Troubleshooting.View(store: $0)
		}
	}

	#if DEBUG
	private func debugSettings(with destinationStore: PresentationStoreOf<Settings.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.debugSettings, action: \.debugSettings)) {
			DebugSettingsCoordinator.View(store: $0)
		}
	}
	#endif
}
