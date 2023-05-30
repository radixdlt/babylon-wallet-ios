import FeaturePrelude
import SecureStorageClient
import SwiftUI

// MARK: - RestoreFromBackup.View
extension RestoreFromBackup {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<RestoreFromBackup>

		public init(store: StoreOf<RestoreFromBackup>) {
			self.store = store
		}
	}
}

extension RestoreFromBackup.View {
	public var body: some View {
		ForceFullScreen {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					// TODO: This is speculative design, needs to be updated once we have the proper design
					VStack(spacing: .medium1) {
						Button(L10n.RestoreFromBackup.importBackupWallet) {
							viewStore.send(.tappedImportProfile)
						}
						.buttonStyle(.primaryRectangular)

						Separator()

						Text(L10n.RestoreFromBackup.cloudBackupWallet)
							.textStyle(.body1Header)
							.flushedLeft

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
								cloudBackupDataCard(item, thisDeviceID: viewStore.thisDeviceID)
							}

							Button(L10n.RestoreFromBackup.useICloudBackup) {
								viewStore.send(.tappedUseCloudBackup)
							}
							.controlState(viewStore.selectedProfileHeader != nil ? .enabled : .disabled)
							.buttonStyle(.primaryRectangular)
						} else {
							Text(L10n.RestoreFromBackup.noCloudBackup)
						}
					}
					.padding(.horizontal, .medium3)
				}
				.fileImporter(
					isPresented: viewStore.binding(
						get: \.isDisplayingFileImporter,
						send: .dismissFileImporter
					),
					allowedContentTypes: [.profile],
					onCompletion: { viewStore.send(.profileImportResult($0.mapError { $0 as NSError })) }
				)
				.navigationTitle(L10n.RestoreFromBackup.navigationTitle)
				.padding(.top, .medium2)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}

	@MainActor
	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>, thisDeviceID: UUID?) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()

		let thisDeviceLabel = L10n.RestoreFromBackup.thisDevice
		let creatingDevice = header.creatingDevice.id == thisDeviceID ? thisDeviceLabel : header.creatingDevice.description.rawValue
		let lastUsedOnDevice = header.lastUsedOnDevice.id == thisDeviceID ? thisDeviceLabel : header.lastUsedOnDevice.description.rawValue

		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text(L10n.RestoreFromBackup.creatingDevice(creatingDevice))
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Group {
						Text(L10n.RestoreFromBackup.creationDateLabel(formatDate(header.creationDate)))
						Text(L10n.RestoreFromBackup.lastUsedOnDeviceLabel(lastUsedOnDevice))
						Text(L10n.RestoreFromBackup.lastModifedDateLabel(formatDate(header.lastModified)))
						Text(L10n.RestoreFromBackup.numberOfNetworksLabel(header.contentHint.numberOfNetworks))
						Text(L10n.RestoreFromBackup.totalAccountsNumberLabel(header.contentHint.numberOfAccountsOnAllNetworksInTotal))
						Text(L10n.RestoreFromBackup.totalPersonasNumberLabel(header.contentHint.numberOfPersonasOnAllNetworksInTotal))
					}
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)

					if !isVersionCompatible {
						Text(L10n.RestoreFromBackup.incompatibleWalletDataLabel)
							.foregroundColor(.red)
							.textStyle(.body2HighImportance)
					}
				}
				if isVersionCompatible {
					Spacer()
					RadioButton(
						appearance: .dark,
						state: item.isSelected ? .selected : .unselected
					)
				}
			}
			.padding(.medium3)
		}
		.disabled(!isVersionCompatible)
	}

	@MainActor
	func formatDate(_ date: Date) -> String {
		date.ISO8601Format(.iso8601Date(timeZone: .current))
	}
}
