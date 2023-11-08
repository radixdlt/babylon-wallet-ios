import ComposableArchitecture
import SwiftUI
extension SelectBackup {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectBackup>

		public init(store: StoreOf<SelectBackup>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium1) {
						Text(L10n.RecoverProfileBackup.Header.subtitle)
							.textStyle(.body1Regular)

						Text(L10n.IOSRecoverProfileBackup.Choose.title)
							.textStyle(.body1Header)

						backupsList(with: viewStore)

						Button(L10n.RecoverProfileBackup.ImportFileButton.title) {
							viewStore.send(.importFromFileInstead)
						}
						.foregroundColor(.app.blue2)
						.font(.app.body1Header)
						.frame(height: .standardButtonHeight)
						.frame(maxWidth: .infinity)
						.padding(.medium1)
						.background(.app.white)
						.cornerRadius(.small2)
					}
					.foregroundColor(.app.gray1)
					.padding(.medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedProfileHeader,
						forAction: { viewStore.send(.tappedUseCloudBackup($0)) },
						control: { action in
							Button(L10n.IOSProfileBackup.useICloudBackup, action: action)
								.buttonStyle(.primaryRectangular)
						}
					)
				}
				.destinations(with: store)
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
				await store.send(.view(.task)).finish()
			}
			.navigationTitle(L10n.RecoverProfileBackup.Header.title)
		}
	}
}

private extension StoreOf<SelectBackup> {
	var destination: PresentationStoreOf<SelectBackup.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SelectBackup>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /SelectBackup.Destination.State.inputEncryptionPassword,
			action: SelectBackup.Destination.Action.inputEncryptionPassword,
			content: { EncryptOrDecryptProfile.View(store: $0).inNavigationView }
		)
	}
}

extension SelectBackup.View {
	@MainActor
	private func backupsList(with viewStore: ViewStoreOf<SelectBackup>) -> some SwiftUI.View {
		// TODO: This is speculative design, needs to be updated once we have the proper design
		VStack(spacing: .medium1) {
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
			} else {
				NoContentView(L10n.IOSRecoverProfileBackup.noBackupsAvailable)
			}
		}
		.padding(.horizontal, .medium3)
	}

	@MainActor
	private func cloudBackupDataCard(_ item: SelectionItem<ProfileSnapshot.Header>, viewStore: ViewStoreOf<SelectBackup>) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()
		let creatingDevice = header.creatingDevice.id == viewStore.thisDeviceID ? L10n.IOSProfileBackup.thisDevice : header.creatingDevice.description
//		let lastUsedOnDevice = header.lastUsedOnDevice.id == viewStore.thisDeviceID ? L10n.IOSProfileBackup.thisDevice : header.lastUsedOnDevice.description.rawValue

		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Group {
						Text(.init(L10n.RecoverProfileBackup.backupFrom(creatingDevice)))
						// FIXME: update bolding of 'label'?
						Text(L10n.IOSProfileBackup.lastModifedDateLabel(formatDate(header.lastModified)))
//						Text(L10n.IOSProfileBackup.numberOfNetworksLabel(header.contentHint.numberOfNetworks))
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
				if isVersionCompatible {
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
		.disabled(!isVersionCompatible)
	}

	@MainActor
	func formatDate(_ date: Date) -> String {
		date.ISO8601Format(.iso8601Date(timeZone: .current))
	}
}
