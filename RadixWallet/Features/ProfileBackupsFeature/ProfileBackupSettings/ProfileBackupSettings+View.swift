import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

extension ProfileBackupSettings.State {
	var viewState: ProfileBackupSettings.ViewState {
		.init(
			isCloudProfileSyncEnabled: isCloudProfileSyncEnabled,
			profileFile: profileFile
		)
	}
}

extension ProfileBackupSettings {
	public struct ViewState: Equatable {
		let isCloudProfileSyncEnabled: Bool
		let profileFile: ExportableProfileFile?

		public var isDisplayingFileExporter: Bool {
			profileFile != nil
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
					.destinations(with: store)
					.exportFileSheet(with: viewStore)
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
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
				Text(L10n.ProfileBackup.headerTitle)
					.padding(.horizontal, .medium2)
					.padding(.vertical, .small1)

				section(L10n.ProfileBackup.AutomaticBackups.title) {
					isCloudProfileSyncEnabled(with: viewStore)
				}

				section(L10n.ProfileBackup.ManualBackups.title) {
					VStack(alignment: .leading, spacing: .medium1) {
						Text(.init(L10n.ProfileBackup.ManualBackups.subtitle))
						Button(L10n.ProfileBackup.ManualBackups.exportButtonTitle) {
							viewStore.send(.exportProfileButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}
				}

				section(L10n.ProfileBackup.DeleteWallet.title) {
					VStack(alignment: .leading, spacing: .medium1) {
						Text(.init(L10n.IOSProfileBackup.DeleteWallet.subtitle))

						Button(L10n.IOSProfileBackup.DeleteWallet.confirmButton) {
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
		_ title: String,
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

private extension StoreOf<ProfileBackupSettings> {
	var destination: PresentationStoreOf<ProfileBackupSettings.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ProfileBackupSettings>) -> some View {
		let destinationStore = store.destination
		return cloudSyncTakesLongTimeAlert(with: destinationStore)
			.disableCloudSyncConfirmationAlert(with: destinationStore)
			.encryptBeforeExportChoiceAlert(with: destinationStore)
			.encryptBeforeExportSheet(with: destinationStore)
			.deleteProfileConfirmationDialog(with: destinationStore)
	}

	private func deleteProfileConfirmationDialog(with destinationStore: PresentationStoreOf<ProfileBackupSettings.Destination>) -> some View {
		confirmationDialog(
			store: destinationStore,
			state: /ProfileBackupSettings.Destination.State.deleteProfileConfirmationDialog,
			action: ProfileBackupSettings.Destination.Action.deleteProfileConfirmationDialog
		)
	}

	private func cloudSyncTakesLongTimeAlert(with destinationStore: PresentationStoreOf<ProfileBackupSettings.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /ProfileBackupSettings.Destination.State.syncTakesLongTimeAlert,
			action: ProfileBackupSettings.Destination.Action.syncTakesLongTimeAlert
		)
	}

	private func disableCloudSyncConfirmationAlert(with destinationStore: PresentationStoreOf<ProfileBackupSettings.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /ProfileBackupSettings.Destination.State.confirmCloudSyncDisable,
			action: ProfileBackupSettings.Destination.Action.confirmCloudSyncDisable
		)
	}

	private func encryptBeforeExportChoiceAlert(with destinationStore: PresentationStoreOf<ProfileBackupSettings.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /ProfileBackupSettings.Destination.State.optionallyEncryptProfileBeforeExporting,
			action: ProfileBackupSettings.Destination.Action.optionallyEncryptProfileBeforeExporting
		)
	}

	private func encryptBeforeExportSheet(with destinationStore: PresentationStoreOf<ProfileBackupSettings.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ProfileBackupSettings.Destination.State.inputEncryptionPassword,
			action: ProfileBackupSettings.Destination.Action.inputEncryptionPassword,
			content: { childStore in
				NavigationView {
					EncryptOrDecryptProfile.View(store: childStore)
				}
			}
		)
	}

	func exportFileSheet(with viewStore: ViewStoreOf<ProfileBackupSettings>) -> some View {
		fileExporter(
			isPresented: viewStore.binding(
				get: \.isDisplayingFileExporter,
				send: .dismissFileExporter
			),
			document: viewStore.profileFile,
			contentType: .profile,
			// Need to disable, since broken in swiftformat 0.52.7
			// swiftformat:disable redundantClosure
			defaultFilename: {
				switch viewStore.profileFile {
				case .plaintext, .none: String.filenameProfileNotEncrypted
				case .encrypted: String.filenameProfileEncrypted
				}
			}(),
			// swiftformat:enable redundantClosure
			onCompletion: { viewStore.send(.profileExportResult($0.mapError { $0 as NSError })) }
		)
	}
}
