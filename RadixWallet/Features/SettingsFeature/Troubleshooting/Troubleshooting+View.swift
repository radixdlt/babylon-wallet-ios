extension Troubleshooting.State {
	var viewState: Troubleshooting.ViewState {
		.init(isLegacyImportEnabled: isLegacyImportEnabled, shareCrashReportsIsEnabled: shareCrashReportsIsEnabled)
	}
}

// MARK: - Troubleshooting.View
extension Troubleshooting {
	struct ViewState: Equatable {
		let isLegacyImportEnabled: Bool
		let shareCrashReportsIsEnabled: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Troubleshooting>

		init(store: StoreOf<Troubleshooting>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.Troubleshooting.title)
				.tint(.primaryText)
				.foregroundColor(.primaryText)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

extension Troubleshooting.View {
	@MainActor
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEachStatic(rows(isLegacyImportEnabled: viewStore.isLegacyImportEnabled, viewStore: viewStore)) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}
			}
			.background(.secondaryBackground)
			.onFirstTask { @MainActor in
				await viewStore.send(.onFirstTask).finish()
			}
		}
	}

	@MainActor
	private func rows(isLegacyImportEnabled: Bool, viewStore: ViewStoreOf<Troubleshooting>) -> [SettingsRow<Troubleshooting>.Kind] {
		[
			.header(L10n.Troubleshooting.accountRecovery),
			.model(
				title: L10n.Troubleshooting.AccountScan.title,
				subtitle: L10n.Troubleshooting.AccountScan.subtitle,
				icon: .asset(.recovery),
				action: .accountScanButtonTapped
			),
			.model(
				title: L10n.Troubleshooting.LegacyImport.title,
				subtitle: L10n.Troubleshooting.LegacyImport.subtitle,
				icon: .asset(.recovery),
				action: .legacyImportButtonTapped
			).valid(if: isLegacyImportEnabled),
			.header("Transaction"),
			.model(
				title: "Raw transaction manifest",
				subtitle: "Paste and submit a manifest using the wallet interaction flow",
				icon: .asset(.code),
				action: .rawManifestButtonTapped
			),
			.header(L10n.Troubleshooting.support),
			.model(
				title: L10n.Troubleshooting.ContactSupport.title,
				subtitle: L10n.Troubleshooting.ContactSupport.subtitle,
				icon: .systemImage("paperplane"),
				accessory: .iconLinkOut,
				action: .contactSupportButtonTapped
			),
			.toggleModel(
				icon: nil,
				title: L10n.AppSettings.CrashReporting.title,
				subtitle: L10n.AppSettings.CrashReporting.subtitle,
				minHeight: .zero,
				isOn: viewStore.binding(
					get: \.shareCrashReportsIsEnabled,
					send: { .crashReportingToggled($0) }
				)
			),
			.header(L10n.Troubleshooting.resetAccount),
			.model(
				title: L10n.Troubleshooting.FactoryReset.title,
				subtitle: L10n.Troubleshooting.FactoryReset.subtitle,
				icon: .systemImage("arrow.clockwise"),
				action: .factoryResetButtonTapped
			),
		]
		.compactMap { $0 }
	}
}

// MARK: - Extensions

private extension StoreOf<Troubleshooting> {
	var destination: PresentationStoreOf<Troubleshooting.Destination> {
		func scopeState(state: State) -> PresentationState<Troubleshooting.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Troubleshooting>) -> some View {
		let destinationStore = store.destination
		return accountRecovery(with: destinationStore)
			.importOlympiaWallet(with: destinationStore)
			.factoryReset(with: destinationStore)
			.rawManifestTransaction(with: destinationStore)
	}

	private func accountRecovery(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.accountRecovery,
			action: Troubleshooting.Destination.Action.accountRecovery,
			content: { ManualAccountRecoveryCoordinator.View(store: $0) }
		)
	}

	private func importOlympiaWallet(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.importOlympiaWallet,
			action: Troubleshooting.Destination.Action.importOlympiaWallet,
			content: { ImportOlympiaWalletCoordinator.View(store: $0) }
		)
	}

	private func factoryReset(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.factoryReset,
			action: Troubleshooting.Destination.Action.factoryReset,
			destination: { FactoryReset.View(store: $0) }
		)
	}

	private func rawManifestTransaction(with destinationStore: PresentationStoreOf<Troubleshooting.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Troubleshooting.Destination.State.rawManifestTransaction,
			action: Troubleshooting.Destination.Action.rawManifestTransaction,
			destination: { RawManifestTransaction.View(store: $0) }
		)
	}
}

private extension SettingsRow.Kind {
	func valid(if condition: Bool) -> Self? {
		condition ? self : nil
	}
}

extension RawManifestTransaction.State {
	var viewState: RawManifestTransaction.ViewState {
		.init(
			mode: mode,
			manifest: manifest,
			sendButtonState: isSending ? .loading(.local) : (canSend ? .enabled : .disabled),
			preAuthorizationResult: preAuthorizationResult
		)
	}
}

extension RawManifestTransaction {
	struct ViewState: Equatable {
		let mode: State.Mode
		let manifest: String
		let sendButtonState: ControlState
		let preAuthorizationResult: String?
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RawManifestTransaction>
		@Dependency(\.pasteboardClient) var pasteboardClient

		init(store: StoreOf<RawManifestTransaction>) {
			self.store = store
		}
	}
}

extension RawManifestTransaction.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			VStack(spacing: .zero) {
				ScrollView {
					VStack(alignment: .leading, spacing: .medium2) {
						#if DEBUG
						Picker(
							"Mode",
							selection: viewStore.binding(
								get: \.mode,
								send: RawManifestTransaction.ViewAction.modeChanged
							)
						) {
							ForEach(RawManifestTransaction.State.Mode.allCases, id: \.self) { mode in
								Text(mode.rawValue).tag(mode)
							}
						}
						.pickerStyle(.segmented)
						#endif

						Text(viewStore.mode == .transaction
							? "Enter a raw transaction manifest to preview and submit to the network."
							: "Enter a raw subintent manifest (ending in YIELD_TO_PARENT) to send as a pre-authorization request.")
							.textStyle(.body1Regular)
							.foregroundColor(.secondaryText)

						if let result = viewStore.preAuthorizationResult {
							VStack(alignment: .leading, spacing: .small2) {
								Text("Signed subintent")
									.textStyle(.body1Header)
								Text(result)
									.textStyle(.monospace)
									.textSelection(.enabled)
								Button {
									pasteboardClient.copyString(result)
								} label: {
									Label("Copy result", systemImage: "doc.on.doc")
										.labelStyle(.titleAndIcon)
								}
								.buttonStyle(.secondaryRectangular(shouldExpand: true))
							}
							.padding(.medium3)
							.background(.primaryBackground)
							.roundedCorners(strokeColor: .border)
						}

						HStack(spacing: .small2) {
							Button {
								let pastedText = pasteboardClient.getString() ?? ""
								viewStore.send(.manifestChanged(pastedText))
							} label: {
								Label("Paste", systemImage: "doc.on.clipboard")
									.labelStyle(.titleAndIcon)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))

							Button {
								viewStore.send(.manifestChanged(""))
							} label: {
								Label("Clear", systemImage: "xmark")
									.labelStyle(.titleAndIcon)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))

							Button {
								pasteboardClient.copyString(viewStore.manifest)
							} label: {
								Label("Copy", systemImage: "doc.on.doc")
									.labelStyle(.titleAndIcon)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))
						}

						AppTextEditor(
							placeholder: "CALL_METHOD\n    Address(\"...\")\n    ...",
							text: viewStore.binding(
								get: \.manifest,
								send: RawManifestTransaction.ViewAction.manifestChanged
							)
						)
						.padding(.medium3)
						.frame(minHeight: 640, alignment: .topLeading)
						.background(.secondaryBackground)
						.roundedCorners(strokeColor: .border)
						.textStyle(.monospace)
						.scrollContentBackground(.hidden)
					}
					.padding(.medium3)
				}

				Separator()

				Button(viewStore.mode == .transaction ? "Transaction Preview" : "Pre-authorization Preview") {
					viewStore.send(.sendTapped)
				}
				.buttonStyle(.primaryRectangular(shouldExpand: true))
				.controlState(viewStore.sendButtonState)
				.padding(.medium3)
			}
			.background(.secondaryBackground)
			.radixToolbar(title: "Submit Transaction Manifest")
		}
	}
}
