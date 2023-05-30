import FeaturePrelude

extension ProfileBackups {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ProfileBackups>

		public init(store: StoreOf<ProfileBackups>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium3) {
					if viewStore.shownInSettings {
						isCloudProfileSyncEnabled(with: viewStore)
					}
					backupsList(with: viewStore)
				}
				.padding(.medium3)
				.alert(
					store: store.scope(state: \.$alert, action: { .view(.alert($0)) }),
					state: /ProfileBackups.Alerts.State.confirmCloudSyncDisable,
					action: ProfileBackups.Alerts.Action.confirmCloudSyncDisable
				)
				.fileImporter(
					isPresented: viewStore.binding(
						get: \.isDisplayingFileImporter,
						send: .dismissFileImporter
					),
					allowedContentTypes: [.profile],
					onCompletion: { viewStore.send(.profileImportResult($0.mapError { $0 as NSError })) }
				)
			}
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
			.navigationTitle(L10n.Settings.backups)
		}
	}
}

extension ProfileBackups.View {
	@MainActor
	private func isCloudProfileSyncEnabled(with viewStore: ViewStoreOf<ProfileBackups>) -> some SwiftUI.View {
		ToggleView(
			title: "Sync Wallet Data to iCloud",
			subtitle: "Warning: If disabled you might lose access to accounts/personas.",
			isOn: viewStore.binding(
				get: \.isCloudProfileSyncEnabled,
				send: { .cloudProfileSyncToggled($0) }
			)
		)
	}

	@MainActor
	private func backupsList(with viewStore: ViewStoreOf<ProfileBackups>) -> some SwiftUI.View {
		ScrollView {
			// TODO: This is speculative design, needs to be updated once we have the proper design
			VStack(spacing: .medium1) {
				if !viewStore.shownInSettings {
					Button("Import Backup Wallet data") {
						viewStore.send(.tappedImportProfile)
					}
					.buttonStyle(.primaryRectangular)
				}

				Separator()

				HStack {
					Text("Cloud Backup Wallet data: ")
						.textStyle(.body1Header)
					Spacer()
				}

				if let backupProfileHeaders = viewStore.backupProfileHeaders {
					Selection(
						viewStore.binding(
							get: \.selectedProfileHeader,
							send: {
								.selectedProfileHeader($0)
							}
						),
						from: backupProfileHeaders
					) { item in
						cloudBackupDataCard(item, viewStore: viewStore)
					}

					if !viewStore.shownInSettings {
						Button("Use iCloud Backup Data") {
							viewStore.send(.tappedUseCloudBackup)
						}
						.controlState(viewStore.selectedProfileHeader != nil ? .enabled : .disabled)
						.buttonStyle(.primaryRectangular)
					}
				} else {
					Text("No Cloud Backup Data")
				}
			}
			.padding(.horizontal, .medium3)
		}
	}

	@MainActor
	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>, viewStore: ViewStoreOf<ProfileBackups>) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()
		let creatingDevice = header.creatingDevice.id == viewStore.thisDeviceID ? "This Device" : header.creatingDevice.description.rawValue
		let lastUsedOnDevice = header.lastUsedOnDevice.id == viewStore.thisDeviceID ? "This Device" : header.lastUsedOnDevice.description.rawValue

		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text("Creating Device: \(creatingDevice)")
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Group {
						Text("Creation Date: \(formatDate(header.creationDate))")
						Text("Last used on device: \(lastUsedOnDevice)")
						Text("Last Modified Date: \(formatDate(header.lastModified))")
						Text("Number of networks: \(header.contentHint.numberOfNetworks)")
						Text("Number of total accounts: \(header.contentHint.numberOfAccountsOnAllNetworksInTotal)")
						Text("Number of total personas: \(header.contentHint.numberOfPersonasOnAllNetworksInTotal)")
					}
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)

					if !isVersionCompatible {
						Text("Incompatible Wallet data")
							.foregroundColor(.red)
							.textStyle(.body2HighImportance)
					}
				}
				if isVersionCompatible, !viewStore.shownInSettings {
					Spacer()
					RadioButton(
						appearance: .dark,
						state: item.isSelected ? .selected : .unselected
					)
				}
			}
			.padding(.medium3)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.disabled(!isVersionCompatible || viewStore.shownInSettings)
	}

	@MainActor
	func formatDate(_ date: Date) -> String {
		date.ISO8601Format(.iso8601Date(timeZone: .current))
	}
}
