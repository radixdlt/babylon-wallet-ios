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
								cloudBackupDataCard(item)
							}

							Button("Use iCloud Backup Data") {
								viewStore.send(.tappedUseCloudBackup)
							}
							.controlState(viewStore.selectedProfileHeader != nil ? .enabled : .disabled)
							.buttonStyle(.primaryRectangular)
						} else {
							Text("No Cloud Backup Data")
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

	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()

		return Card(action: item.action, isDisabled: !isVersionCompatible) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					// TODO: Proper fields to be updated based on the final UX
					Text("Creating Device: \(header.creatingDevice.description.rawValue)")
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
					Group {
						Text("Creation Date: \(formatDate(header.creationDate))")
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
				if isVersionCompatible {
					RadioButton(
						appearance: .dark,
						state: item.isSelected ? .selected : .unselected
					)
				}
			}
			.padding(.medium2)
		}
	}

	func formatDate(_ date: Date) -> String {
		formatter.dateFormat = "d MMM YYY"
		return formatter.string(from: date)
	}
}
