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

						// FIXME: Strings
						Button("Export Wallet Backup File") {
							viewStore.send(.exportProfileButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
					backupsList(with: viewStore)
				}
				.padding(.medium3)
				.alert(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.confirmCloudSyncDisable,
					action: ProfileBackups.Destinations.Action.confirmCloudSyncDisable
				)
				.alert(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.optionallyEncryptProfileBeforeExporting,
					action: ProfileBackups.Destinations.Action.optionallyEncryptProfileBeforeExporting
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.importMnemonic,
					action: ProfileBackups.Destinations.Action.importMnemonic,
					content: { store in
						NavigationView {
							ImportMnemonic.View(store: store)
								.navigationTitle(L10n.ImportMnemonic.navigationTitle)
						}
					}
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ProfileBackups.Destinations.State.inputEncryptionPassword,
					action: ProfileBackups.Destinations.Action.inputEncryptionPassword,
					content: { store in
						NavigationView {
							InputEncryptionPassword.View(store: store)
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
				.fileExporter(
					isPresented: viewStore.binding(
						get: \.isDisplayingFileExporter,
						send: .dismissFileExporter
					),
					document: viewStore.profileFilePotentiallyEncrypted,
					contentType: .profile,
					defaultFilename: viewStore.profileFilePotentiallyEncrypted.map {
						switch $0 {
						case .plaintext: return String.filenameProfileNotEncrypted
						case .encrypted: return String.filenameProfileEncrypted
						}
					} ?? String.filenameProfileNotEncrypted,
					onCompletion: { viewStore.send(.profileExportResult($0.mapError { $0 as NSError })) }
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
			title: L10n.IOSProfileBackup.ProfileSync.title,
			subtitle: L10n.IOSProfileBackup.ProfileSync.subtitle,
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
					Button(L10n.IOSProfileBackup.importBackupWallet) {
						viewStore.send(.tappedImportProfile)
					}
					.buttonStyle(.primaryRectangular)
				}

				Separator()

				HStack {
					Text(L10n.IOSProfileBackup.cloudBackupWallet)
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
								Button(L10n.IOSProfileBackup.useICloudBackup, action: action)
									.buttonStyle(.primaryRectangular)
							}
						)
					}
				} else {
					Text(L10n.IOSProfileBackup.noCloudBackup)
				}
			}
			.padding(.horizontal, .medium3)
		}
	}

	@MainActor
	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>, viewStore: ViewStoreOf<ProfileBackups>) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()
		let creatingDevice = header.creatingDevice.id == viewStore.thisDeviceID ? L10n.IOSProfileBackup.thisDevice : header.creatingDevice.description.rawValue
		let lastUsedOnDevice = header.lastUsedOnDevice.id == viewStore.thisDeviceID ? L10n.IOSProfileBackup.thisDevice : header.lastUsedOnDevice.description.rawValue

		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text(L10n.IOSProfileBackup.creatingDevice(creatingDevice))
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Group {
						Text(L10n.IOSProfileBackup.creationDateLabel(formatDate(header.creationDate)))
						Text(L10n.IOSProfileBackup.lastUsedOnDeviceLabel(lastUsedOnDevice))
						Text(L10n.IOSProfileBackup.lastModifedDateLabel(formatDate(header.lastModified)))
						Text(L10n.IOSProfileBackup.numberOfNetworksLabel(header.contentHint.numberOfNetworks))
						Text(L10n.IOSProfileBackup.totalAccountsNumberLabel(header.contentHint.numberOfAccountsOnAllNetworksInTotal))
						Text(L10n.IOSProfileBackup.totalPersonasNumberLabel(header.contentHint.numberOfPersonasOnAllNetworksInTotal))
					}
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)

					if !isVersionCompatible {
						Text(L10n.IOSProfileBackup.incompatibleWalletDataLabel)
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
