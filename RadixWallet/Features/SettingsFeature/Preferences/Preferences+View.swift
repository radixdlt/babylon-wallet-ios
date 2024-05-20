extension Preferences.State {
	var viewState: Preferences.ViewState {
		let isDeveloperModeEnabled = appPreferences?.security.isDeveloperModeEnabled ?? false
		#if DEBUG
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled,
			exportLogsUrl: exportLogsUrl
		)
		#else
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled
		)
		#endif
	}
}

// MARK: - Preferences.View

public extension Preferences {
	struct ViewState: Equatable {
		let isDeveloperModeEnabled: Bool
		#if DEBUG
		let exportLogsUrl: URL?
		init(isDeveloperModeEnabled: Bool, exportLogsUrl: URL?) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
			self.exportLogsUrl = exportLogsUrl
		}
		#else
		init(isDeveloperModeEnabled: Bool) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
		#endif
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Preferences>

		public init(store: StoreOf<Preferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.Preferences.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

extension Preferences.View {
	@MainActor
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEach(rows) { kind in
						SettingsRow(kind: kind, store: store)
					}

					developerMode(viewStore: viewStore)

					#if DEBUG
					exportLogs(viewStore: viewStore)
					#endif
				}
			}
			.background(Color.app.gray5)
			.onAppear {
				viewStore.send(.appeared)
			}
		}
	}

	@MainActor
	private var rows: [SettingsRow<Preferences>.Kind] {
		[
			.separator,
			.model(
				title: L10n.Preferences.DepositGuarantees.title,
				subtitle: L10n.Preferences.DepositGuarantees.subtitle,
				icon: .asset(AssetResource.depositGuarantees),
				action: .depositGuaranteesButtonTapped
			),
			.model(
				title: L10n.Preferences.HiddenEntities.title,
				subtitle: L10n.Preferences.HiddenEntities.subtitle,
				icon: .systemImage("eye.fill"),
				action: .hiddenEntitiesButtonTapped
			),
			.header(L10n.Preferences.advancedPreferences),
			.model(
				title: L10n.Preferences.gateways,
				icon: .asset(AssetResource.gateway),
				action: .gatewaysButtonTapped
			),
		]
	}

	private func developerMode(viewStore: ViewStoreOf<Preferences>) -> some View {
		ToggleView(
			icon: AssetResource.developerMode,
			title: L10n.Preferences.DeveloperMode.title,
			subtitle: L10n.Preferences.DeveloperMode.subtitle,
			minHeight: .zero,
			isOn: viewStore.binding(
				get: \.isDeveloperModeEnabled,
				send: { .developerModeToogled($0) }
			)
		)
		.padding(.horizontal, .medium3)
		.padding(.vertical, .medium1)
		.background(Color.app.white)
		.withSeparator
	}

	#if DEBUG
	@MainActor
	private func exportLogs(viewStore: ViewStoreOf<Preferences>) -> some View {
		SettingsRow(
			kind: .model(
				title: "Export logs",
				subtitle: "Export and save debugging logs",
				icon: .asset(AssetResource.appSettings),
				action: .exportLogsButtonTapped
			),
			store: store
		)
		.sheet(item: viewStore.binding(get: \.exportLogsUrl, send: { _ in .exportLogsDismissed })) { item in
			ShareView(items: [item])
		}
	}
	#endif
}

private extension StoreOf<Preferences> {
	var destination: PresentationStoreOf<Preferences.Destination> {
		func scopeState(state: State) -> PresentationState<Preferences.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Preferences>) -> some View {
		let destinationStore = store.destination
		return depositGuarantees(with: destinationStore)
			.hiddenEntities(with: destinationStore)
			.gateways(with: destinationStore)
	}

	private func depositGuarantees(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Preferences.Destination.State.depositGuarantees,
			action: Preferences.Destination.Action.depositGuarantees,
			destination: { DefaultDepositGuarantees.View(store: $0) }
		)
	}

	private func hiddenEntities(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Preferences.Destination.State.hiddenEntities,
			action: Preferences.Destination.Action.hiddenEntities,
			destination: { AccountAndPersonaHiding.View(store: $0) }
		)
	}

	private func gateways(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Preferences.Destination.State.gateways,
			action: Preferences.Destination.Action.gateways,
			destination: { GatewaySettings.View(store: $0) }
		)
	}
}
