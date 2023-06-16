import FeaturePrelude
import ImportMnemonicFeature

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
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.confirmCloudSyncDisable,
					action: ProfileBackups.Destinations.Action.confirmCloudSyncDisable
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.importMnemonic,
					action: ProfileBackups.Destinations.Action.importMnemonic,
					content: { store in
						NavigationView {
							ImportMnemonic.View(store: store)
								.navigationTitle("Import Seed Phrase") // FIXME: strings
						}
					}
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
			title: "Sync Wallet Data to iCloud", // FIXME: strings
			subtitle: "Warning: If disabled you might lose access to accounts/personas.", // FIXME: strings
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
					Button("Import Backup Wallet data") { // FIXME: strings
						viewStore.send(.tappedImportProfile)
					}
					.buttonStyle(.primaryRectangular)
				}

				Separator()

				HStack {
					Text("Wallet backups in your iCloud account:") // FIXME: strings
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
						WithControlRequirements(
							viewStore.selectedProfileHeader,
							forAction: { viewStore.send(.tappedUseCloudBackup($0)) },
							control: { action in
								Button("Use iCloud Backup Data", action: action)
									.buttonStyle(.primaryRectangular)
							}
						)
					}
				} else {
					Text("No Cloud Backup Data") // FIXME: strings
				}
			}
			.padding(.horizontal, .medium3)
		}
	}

	@MainActor
	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>, viewStore: ViewStoreOf<ProfileBackups>) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()
		let creatingDevice = header.creatingDevice.id == viewStore.thisDeviceID ? "This Device" : header.creatingDevice.description.rawValue // FIXME: strings
		let lastUsedOnDevice = header.lastUsedOnDevice.id == viewStore.thisDeviceID ? "This Device" : header.lastUsedOnDevice.description.rawValue // FIXME: strings

		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text("Creating Device: \(creatingDevice)")
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Group {
						Text("Creation Date: \(formatDate(header.creationDate))") // FIXME: strings
						Text("Last used on device: \(lastUsedOnDevice)") // FIXME: strings
						Text("Last Modified Date: \(formatDate(header.lastModified))") // FIXME: strings
						Text("Number of networks: \(header.contentHint.numberOfNetworks)") // FIXME: strings
						Text("Number of total accounts: \(header.contentHint.numberOfAccountsOnAllNetworksInTotal)") // FIXME: strings
						Text("Number of total personas: \(header.contentHint.numberOfPersonasOnAllNetworksInTotal)") // FIXME: strings
					}
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)

					if !isVersionCompatible {
						Text("Incompatible Wallet data") // FIXME: strings
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
