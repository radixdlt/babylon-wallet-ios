import FeaturePrelude
import ImportMnemonicFeature

extension ProfileBackupSettings.State {
	var viewState: ProfileBackupSettings.ViewState {
		.init(
			isCloudProfileSyncEnabled: isCloudProfileSyncEnabled,
			profileFilePotentiallyEncrypted: profileFilePotentiallyEncrypted
		)
	}
}

extension ProfileBackupSettings {
	public struct ViewState: Equatable {
		let isCloudProfileSyncEnabled: Bool
		let profileFilePotentiallyEncrypted: ExportableProfileFile?

		public var isDisplayingFileExporter: Bool {
			profileFilePotentiallyEncrypted != nil
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ProfileBackupSettings>

		public init(store: StoreOf<ProfileBackupSettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				coreView(with: viewStore)
					.cloudSyncTakesLongTimeAlert(with: store)
					.disableCloudSyncConfirmationAlert(with: store)
					.encryptBeforeExportChoiceAlert(with: store)
					.encryptBeforeExportSheet(with: store)
					.deleteProfileConfirmationDialog(with: store)
					.exportFileSheet(with: viewStore)
			}
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
			.navigationTitle(L10n.Settings.backups)
		}
	}
}

extension ProfileBackupSettings.View {
	@MainActor
	@ViewBuilder
	private func coreView(with viewStore: ViewStoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		ScrollView {
			VStack(alignment: .leading, spacing: .large3) {
				// FIXME: Strings
				VStack(alignment: .leading, spacing: .medium1) {
					Text("Backing up your wallet ensure you can recover access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).")

					Text("For security, backups do not contain any seed phrases or private keys. You must write them down separatly.")
						.fontWeight(.bold)
				}
				.padding(.horizontal, .medium2)
				.padding(.vertical, .small1)

				// FIXME: Strings
				section("Automatic Backups (recommended)") {
					isCloudProfileSyncEnabled(with: viewStore)
				}

				// FIXME: Strings
				section("Manual backups") {
					VStack(alignment: .leading, spacing: .medium1) {
						Text("A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).")
						Text("Only the **curent configuration** of your wallet is backed up with each manual export")
						Button("Export Wallet Backup File") {
							viewStore.send(.exportProfileButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}
				}

				// FIXME: Strings
				section("Delete wallet") {
					VStack(alignment: .leading, spacing: .medium1) {
						Text("You may delete your wallet. this will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.")
						Text("**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")

						Button("Delete Wallet and iCloud Backup") {
							viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
						}
						.foregroundColor(.app.white)
						.font(.app.body1Header)
						.frame(height: .standardButtonHeight)
						.frame(maxWidth: .infinity)
						.padding(.horizontal, .medium1)
						.background(.app.red1)
						.cornerRadius(.small2)
					}
				}
			}
		}
		.background(Color.app.gray5)
		.foregroundColor(.app.gray2)
		.textStyle(.body1HighImportance)
		.multilineTextAlignment(.leading)
	}

	@MainActor
	@ViewBuilder
	private func section(
		_ title: LocalizedStringKey,
		@ViewBuilder content: () -> some SwiftUI.View
	) -> some SwiftUI.View {
		VStack(alignment: .leading, spacing: .small1) {
			Text(title)
				.padding(.horizontal, .medium2)
				.background(Color.app.gray5)

			content()
				.padding(.horizontal, .medium2)
				.padding(.vertical, .small1)
				.background(Color.app.white)
		}
	}

	@MainActor
	private func isCloudProfileSyncEnabled(with viewStore: ViewStoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		HStack {
			Image(asset: AssetResource.backups)

			ToggleView(
				title: L10n.IOSProfileBackup.ProfileSync.title,
				subtitle: L10n.IOSProfileBackup.ProfileSync.subtitle,
				isOn: viewStore.binding(
					get: \.isCloudProfileSyncEnabled,
					send: { .cloudProfileSyncToggled($0) }
				)
			)
		}
	}
}

extension SwiftUI.View {
	@MainActor
	fileprivate func deleteProfileConfirmationDialog(with store: StoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		confirmationDialog(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /ProfileBackupSettings.Destinations.State.deleteProfileConfirmationDialog,
			action: ProfileBackupSettings.Destinations.Action.deleteProfileConfirmationDialog
		)
	}

	@MainActor
	fileprivate func cloudSyncTakesLongTimeAlert(with store: StoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		alert(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /ProfileBackupSettings.Destinations.State.syncTakesLongTimeAlert,
			action: ProfileBackupSettings.Destinations.Action.syncTakesLongTimeAlert
		)
	}

	@MainActor
	fileprivate func disableCloudSyncConfirmationAlert(with store: StoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		alert(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /ProfileBackupSettings.Destinations.State.confirmCloudSyncDisable,
			action: ProfileBackupSettings.Destinations.Action.confirmCloudSyncDisable
		)
	}

	@MainActor
	fileprivate func encryptBeforeExportChoiceAlert(with store: StoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		alert(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /ProfileBackupSettings.Destinations.State.optionallyEncryptProfileBeforeExporting,
			action: ProfileBackupSettings.Destinations.Action.optionallyEncryptProfileBeforeExporting
		)
	}

	@MainActor
	fileprivate func encryptBeforeExportSheet(with store: StoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /ProfileBackupSettings.Destinations.State.inputEncryptionPassword,
			action: ProfileBackupSettings.Destinations.Action.inputEncryptionPassword,
			content: { store_ in
				NavigationView {
					EncryptOrDecryptProfile.View(store: store_)
				}
			}
		)
	}

	@MainActor
	fileprivate func exportFileSheet(with viewStore: ViewStoreOf<ProfileBackupSettings>) -> some SwiftUI.View {
		fileExporter(
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
}
