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
				coreView(store, with: viewStore)
					.toolbar {
						ToolbarItem(placement: .automatic) {
							CloseButton {
								store.send(.view(.closeButtonTapped))
							}
						}
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
		}
	}
}

extension SelectBackup.View {
	@MainActor
	@ViewBuilder
	private func coreView(_ store: StoreOf<SelectBackup>, with viewStore: ViewStoreOf<SelectBackup>) -> some SwiftUI.View {
		ScrollView {
			VStack(spacing: .medium1) {
				Text(L10n.RecoverProfileBackup.Header.title)
					.multilineTextAlignment(.center)
					.textStyle(.sheetTitle)

				Text(L10n.RecoverProfileBackup.Header.subtitle)
					.textStyle(.body1Regular)

				Text(L10n.IOSRecoverProfileBackup.Choose.title)
					.textStyle(.body1Header)

				backupsList(with: viewStore)

				VStack(alignment: .center, spacing: .small1) {
					selectFileInsteadButton(with: store)
					Divider()
					restoreWithoutProfile(with: store)
				}
			}
			.foregroundColor(.app.gray1)
			.padding(.medium2)
		}
		.modifier {
			if #available(iOS 17, *) {
				$0.scrollIndicatorsFlash(onAppear: true)
			} else {
				$0
			}
		}
	}

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
		return Card(action: item.action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Group {
						// Contains bold text segments.
						Text(LocalizedStringKey(L10n.RecoverProfileBackup.backupFrom(creatingDevice)))
						Text(L10n.IOSProfileBackup.lastModifedDateLabel(formatDate(header.lastModified)))

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

	@MainActor
	private func selectFileInsteadButton(with store: StoreOf<SelectBackup>) -> some SwiftUI.View {
		secondaryButton(title: L10n.RecoverProfileBackup.ImportFileButton.title, store: store, action: .importFromFileInstead)
	}

	@MainActor
	@ViewBuilder
	private func restoreWithoutProfile(with store: StoreOf<SelectBackup>) -> some SwiftUI.View {
		// FIXME: Strings
		Text("Backup not available?")
			.textStyle(.body1Header)
			.foregroundColor(.app.gray1)

		// FIXME: Strings
		secondaryButton(title: "Other Restore Options", store: store, action: .otherRestoreOptionsTapped)
	}

	@MainActor
	private func secondaryButton(title: String, store: StoreOf<SelectBackup>, action: SelectBackup.ViewAction) -> some SwiftUI.View {
		Button(title) {
			store.send(.view(action))
		}
		.buttonStyle(.alternativeRectangular)
	}
}

private extension StoreOf<SelectBackup> {
	var destination: PresentationStoreOf<SelectBackup.Destination> {
		func scopeState(state: State) -> PresentationState<SelectBackup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SelectBackup>) -> some View {
		let destinationStore = store.destination
		return self
			.inputEncryptionPassword(with: destinationStore)
			.recoverWalletWithoutProfileCoordinator(with: destinationStore)
	}

	private func inputEncryptionPassword(with destinationStore: PresentationStoreOf<SelectBackup.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SelectBackup.Destination.State.inputEncryptionPassword,
			action: SelectBackup.Destination.Action.inputEncryptionPassword,
			content: { EncryptOrDecryptProfile.View(store: $0).inNavigationView }
		)
	}

	private func recoverWalletWithoutProfileCoordinator(with destinationStore: PresentationStoreOf<SelectBackup.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /SelectBackup.Destination.State.recoverWalletWithoutProfileCoordinator,
			action: SelectBackup.Destination.Action.recoverWalletWithoutProfileCoordinator,
			content: { RecoverWalletWithoutProfileCoordinator.View(store: $0) }
		)
	}
}
