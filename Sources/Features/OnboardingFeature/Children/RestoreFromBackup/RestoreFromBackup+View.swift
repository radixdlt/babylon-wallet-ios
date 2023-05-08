import FeaturePrelude
import SecureStorageClient
import SwiftUI

// MARK: - RestoreFromBackup.View
extension RestoreFromBackup {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<RestoreFromBackup>
		let formatter = DateFormatter()

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
						Button("Import Backup data") {
							viewStore.send(.tappedImportProfile)
						}
						.buttonStyle(.primaryRectangular)

						Separator()

						HStack {
							Text("iCloud Backup data: ")
								.textStyle(.body1Header)
							Spacer()
						}

						if let backupProfiles = viewStore.backupProfiles {
							Selection(
								viewStore.binding(
									get: \.selectedProfile,
									send: {
										.selectedProfile($0)
									}
								),
								from: backupProfiles
							) { item in
								iCloudBackupDataCard(item)
									.onTapGesture {
										item.action()
									}
							}

							Button("Use iCloud Backup Data") {
								viewStore.send(.tappedUseICloudBackup)
							}
							.controlState(viewStore.selectedProfile != nil ? .enabled : .disabled)
							.buttonStyle(.primaryRectangular)
						} else {
							Text("No iCloud Backup Data")
						}
					}
					.padding([.horizontal, .bottom], .medium1)
				}
				.fileImporter(
					isPresented: viewStore.binding(
						get: \.isDisplayingFileImporter,
						send: .dismissFileImporter
					),
					allowedContentTypes: [.profile],
					onCompletion: { viewStore.send(.profileImported($0.mapError { $0 as NSError })) }
				)
				.navigationTitle("Wallet Data Backup")
				.padding(.top, .medium2)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}

	private func iCloudBackupDataCard(_ item: SelectionItem<Profile>) -> some View {
		let profile = item.value

		return Card {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text("Creating Device: \(profile.header.creatingDevice.description)")
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Text("Creation Date: \(formatDate(profile.header.creationDate))")
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
					Text("Last Modified Date: \(formatDate(profile.header.lastModified))")
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
				}
				RadioButton(
					appearance: .dark,
					state: item.isSelected ? .selected : .unselected
				)
			}
			.padding(.medium2)
		}
	}

	func formatDate(_ date: Date) -> String {
		formatter.dateFormat = "d MMM YYY"
		return formatter.string(from: date)
	}
}
