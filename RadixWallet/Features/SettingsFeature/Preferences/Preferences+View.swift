extension Preferences.State {
	var viewState: Preferences.ViewState {
		let isDeveloperModeEnabled = appPreferences?.security.isDeveloperModeEnabled ?? false
		let isAdvancedLockEnabled = appPreferences?.security.isAdvancedLockEnabled ?? false
		#if DEBUG
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled,
			isAdvancedLockEnabled: isAdvancedLockEnabled,
			exportLogsUrl: exportLogsUrl
		)
		#else
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled,
			isAdvancedLockEnabled: isAdvancedLockEnabled
		)
		#endif
	}
}

// MARK: - Preferences.View

extension Preferences {
	struct ViewState: Equatable {
		let isDeveloperModeEnabled: Bool
		let isAdvancedLockEnabled: Bool
		#if DEBUG
		let exportLogsUrl: URL?
		init(
			isDeveloperModeEnabled: Bool,
			isAdvancedLockEnabled: Bool,
			exportLogsUrl: URL?
		) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
			self.isAdvancedLockEnabled = isAdvancedLockEnabled
			self.exportLogsUrl = exportLogsUrl
		}
		#else
		init(
			isDeveloperModeEnabled: Bool,
			isAdvancedLockEnabled: Bool
		) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
			self.isAdvancedLockEnabled = isAdvancedLockEnabled
		}
		#endif
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Preferences>

		init(store: StoreOf<Preferences>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
					ForEachStatic(rows(viewStore: viewStore)) { kind in
						SettingsRow(kind: kind, store: store)
					}

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
	private func rows(viewStore: ViewStoreOf<Preferences>) -> [SettingsRow<Preferences>.Kind] {
		let advancedLockToggle: SettingsRow<Preferences>.Kind? = if #unavailable(iOS 18) {
			.toggleModel(
				icon: .advancedLock,
				title: L10n.Preferences.AdvancedLock.title,
				subtitle: L10n.Preferences.AdvancedLock.subtitle,
				minHeight: .zero,
				isOn: viewStore.binding(
					get: \.isAdvancedLockEnabled,
					send: { .advancedLockToogled($0) }
				)
			)
		} else {
			nil
		}

		return [
			.separator,
			.model(
				title: L10n.Preferences.DepositGuarantees.title,
				subtitle: L10n.Preferences.DepositGuarantees.subtitle,
				icon: .asset(.depositGuarantees),
				action: .depositGuaranteesButtonTapped
			),
			.header(L10n.Preferences.displayPreferences),
			.model(
				title: L10n.Preferences.HiddenEntities.title,
				subtitle: L10n.Preferences.HiddenEntities.subtitle,
				icon: .systemImage("eye.fill"),
				action: .hiddenEntitiesButtonTapped
			),
			.model(
				title: L10n.Preferences.HiddenAssets.title,
				subtitle: L10n.Preferences.HiddenAssets.subtitle,
				icon: .systemImage("eye.fill"),
				action: .hiddenAssetsButtonTapped
			),
			advancedLockToggle,
			.header(L10n.Preferences.advancedPreferences),
			.model(
				title: L10n.Preferences.gateways,
				icon: .asset(.gateway),
				action: .gatewaysButtonTapped
			),
			.toggleModel(
				icon: .developerMode,
				title: L10n.Preferences.DeveloperMode.title,
				subtitle: L10n.Preferences.DeveloperMode.subtitle,
				minHeight: .zero,
				isOn: viewStore.binding(
					get: \.isDeveloperModeEnabled,
					send: { .developerModeToogled($0) }
				)
			),
		].compactMap { $0 }
	}

	#if DEBUG
	@MainActor
	private func exportLogs(viewStore: ViewStoreOf<Preferences>) -> some View {
		SettingsRow(
			kind: .model(
				title: "Export logs",
				subtitle: "Export and save debugging logs",
				icon: .asset(.appSettings),
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
			.hiddenAssets(with: destinationStore)
			.gateways(with: destinationStore)
	}

	private func depositGuarantees(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.depositGuarantees, action: \.depositGuarantees)) {
			DefaultDepositGuarantees.View(store: $0)
		}
	}

	private func hiddenEntities(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.hiddenEntities, action: \.hiddenEntities)) {
			HiddenEntities.View(store: $0)
		}
	}

	private func hiddenAssets(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.hiddenAssets, action: \.hiddenAssets)) {
			HiddenAssets.View(store: $0)
		}
	}

	private func gateways(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.gateways, action: \.gateways)) {
			GatewaySettings.View(store: $0)
		}
	}
}
