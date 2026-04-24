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
				.tint(.primaryText)
				.foregroundColor(.primaryText)
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
			.background(Color.secondaryBackground)
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
			.model(
				title: L10n.Preferences.AddressBook.title,
				subtitle: L10n.Preferences.AddressBook.subtitle,
				icon: .systemImage("book.closed.fill"),
				action: .addressBookButtonTapped
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
			.model(
				title: L10n.Preferences.ThemeSelection.title,
				subtitle: L10n.Preferences.ThemeSelection.subtitle,
				icon: .systemImage("circle.righthalf.filled"),
				action: .themeSelectionButtonTapped
			),
			.header(L10n.Preferences.advancedPreferences),
			.model(
				title: L10n.Preferences.gateways,
				icon: .asset(.gateway),
				action: .gatewaysButtonTapped
			),
			.model(
				title: "Signaling Servers",
				subtitle: "Manage signaling server and ICE profile options.",
				icon: .systemImage("dot.radiowaves.left.and.right"),
				action: .signalingServersButtonTapped
			),
			.model(
				title: "Relay Services",
				subtitle: "Manage relay service endpoints for Radix Connect Mobile.",
				icon: .systemImage("point.3.connected.trianglepath.dotted"),
				action: .relayServicesButtonTapped
			),
			.model(
				title: "Token Price Services",
				subtitle: "Manage token price service URLs",
				icon: .systemImage("dollarsign.circle.fill"),
				action: .tokenPriceServicesButtonTapped
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
			.addressBook(with: destinationStore)
			.themeSelection(with: destinationStore)
			.gateways(with: destinationStore)
			.signalingServers(with: destinationStore)
			.relayServices(with: destinationStore)
			.tokenPriceServices(with: destinationStore)
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

	private func addressBook(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.addressBook, action: \.addressBook)) {
			AddressBook.View(store: $0)
		}
	}

	private func gateways(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.gateways, action: \.gateways)) {
			GatewaySettings.View(store: $0)
		}
	}

	private func signalingServers(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.signalingServers, action: \.signalingServers)) {
			SignalingServersSettings.View(store: $0)
		}
	}

	private func relayServices(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.relayServices, action: \.relayServices)) {
			RelayServicesSettings.View(store: $0)
		}
	}

	private func tokenPriceServices(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.tokenPriceServices, action: \.tokenPriceServices)) {
			TokenPriceServicesSettings.View(store: $0)
		}
	}

	private func themeSelection(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.themeSelection, action: \.themeSelection)) {
			ThemeSelection.View(store: $0)
		}
	}
}

// MARK: - TokenPriceServicesSettings.View
extension TokenPriceServicesSettings {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<TokenPriceServicesSettings>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .medium3) {
						Text("Manage token price service URLs used to fetch token prices on the current network.")
							.textStyle(.body1HighImportance)
							.foregroundColor(.secondaryText)

						if store.rows.isEmpty {
							emptyState
						} else {
							ForEachStatic(store.rows) { row in
								serviceRow(row)
							}
						}
					}
					.padding(.medium3)
				}
				.background(.secondaryBackground)
				.radixToolbar(title: "Token Price Services")
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							store.send(.view(.addButtonTapped))
						} label: {
							Image(systemName: "plus")
						}
						.accessibilityLabel("Add Token Price Service")
					}
				}
				.task {
					store.send(.view(.task))
				}
				.destinations(with: store)
			}
		}

		private var emptyState: some SwiftUI.View {
			Text("No token price services added yet.")
				.textStyle(.body1HighImportance)
				.foregroundColor(.secondaryText)
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.padding(.medium3)
				.addressBookEntrySurface()
		}

		private func serviceRow(_ row: TokenPriceServicesSettings.State.Row) -> some SwiftUI.View {
			HStack(spacing: .small2) {
				Text(row.service.baseUrl.absoluteString)
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)
					.lineLimit(2)
					.frame(maxWidth: .infinity, alignment: .leading)

				Button(asset: AssetResource.trash) {
					store.send(.view(.deleteTapped(row.service.baseUrl)))
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Remove Token Price Service")
			}
			.padding(.medium3)
			.addressBookEntrySurface()
		}
	}
}

extension AddTokenPriceService.State {
	var urlHint: Hint.ViewState? {
		errorText.map(Hint.ViewState.iconError)
	}
}

// MARK: - AddTokenPriceService.View
extension AddTokenPriceService {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<AddTokenPriceService>
		@FocusState private var focusedField: State.Field?
		@Environment(\.dismiss) private var dismiss

		init(store: StoreOf<AddTokenPriceService>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			content
				.withNavigationBar {
					dismiss()
				}
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						Text("Add Token Price Service")
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text("Enter a token price service URL")
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: "URL",
							text: $store.url.sending(\.view.urlChanged),
							hint: store.urlHint,
							focus: .on(
								.url,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.padding(.top, .small3)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						.autocorrectionDisabled()
					}
					.padding(.top, .medium3)
					.padding(.horizontal, .large2)
					.padding(.bottom, .medium1)
				}
				.footer {
					Button("Add") {
						store.send(.view(.addButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.addButtonState)
				}
				.onAppear {
					store.send(.view(.appeared))
				}
			}
		}
	}
}

private extension StoreOf<TokenPriceServicesSettings> {
	var destination: PresentationStoreOf<TokenPriceServicesSettings.Destination> {
		func scopeState(state: State) -> PresentationState<TokenPriceServicesSettings.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<TokenPriceServicesSettings>) -> some View {
		let destinationStore = store.destination
		return addService(with: destinationStore)
			.deleteAlert(with: destinationStore)
	}

	private func addService(with destinationStore: PresentationStoreOf<TokenPriceServicesSettings.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addService, action: \.addService)) {
			AddTokenPriceService.View(store: $0)
		}
	}

	private func deleteAlert(with destinationStore: PresentationStoreOf<TokenPriceServicesSettings.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.deleteAlert, action: \.deleteAlert))
	}
}
