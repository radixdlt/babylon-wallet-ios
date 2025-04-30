import ComposableArchitecture
import SwiftUI

extension SelectBackup {
	typealias ViewState = State

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SelectBackup>

		init(store: StoreOf<SelectBackup>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				coreView(store, with: viewStore)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								store.send(.view(.closeButtonTapped))
							}
						}
					}
					.footer {
						WithControlRequirements(
							viewStore.selectedProfile,
							forAction: { viewStore.send(.tappedUseCloudBackup($0.id)) },
							control: { action in
								Button(L10n.Common.continue, action: action)
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
	private func coreView(_ store: StoreOf<SelectBackup>, with viewStore: ViewStoreOf<SelectBackup>) -> some View {
		ScrollView {
			VStack(spacing: .medium1) {
				VStack(spacing: .medium3) {
					Text(L10n.RecoverProfileBackup.Header.title)
						.textStyle(.sheetTitle)

					Text(L10n.RecoverProfileBackup.Header.subtitle)
						.textStyle(.body1Regular)
				}
				.multilineTextAlignment(.center)
				.padding(.horizontal, .small2)

				Text(L10n.RecoverProfileBackup.Choose.ios)
					.textStyle(.body1Header)

				switch viewStore.status {
				case .start, .migrating, .loading:
					ProgressView()
				case .loaded:
					backupsList(with: viewStore)
				case .failed(.accountTemporarilyUnavailable), .failed(.notAuthenticated):
					failureBox(message: L10n.RecoverProfileBackup.NotLoggedIn.ios)
				case .failed(.networkUnavailable):
					failureBox(message: L10n.RecoverProfileBackup.networkUnavailable)
				case .failed(.other):
					failureBox(message: L10n.RecoverProfileBackup.couldNotLoadBackups)
				}

				Button(L10n.RecoverProfileBackup.ImportFileButton.title) {
					store.send(.view(.importFromFileInstead))
				}
				.buttonStyle(.alternativeRectangular)

				Divider()

				VStack(spacing: .medium3) {
					Text(L10n.RecoverProfileBackup.backupNotAvailable)
						.textStyle(.body1Header)

					Button(L10n.RecoverProfileBackup.otherRestoreOptionsButton) {
						store.send(.view(.otherRestoreOptionsTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
				.padding(.horizontal, .medium1)
			}
			.padding(.horizontal, .medium1)
			.padding(.bottom, .medium1)
			.foregroundColor(.primaryText)
		}
	}

	private func failureBox(message: String) -> some View {
		Text(message)
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray2)
			.padding(.vertical, .large1)
			.padding(.horizontal, .large2)
			.frame(maxWidth: .infinity)
			.background(.secondaryBackground)
			.roundedCorners(radius: .small1)
	}

	@MainActor
	private func backupsList(with viewStore: ViewStoreOf<SelectBackup>) -> some View {
		VStack(spacing: .medium2) {
			if let backedUpProfiles = viewStore.backedUpProfiles {
				Selection(
					viewStore.binding(get: \.selectedProfile) { .selectedProfile($0) },
					from: backedUpProfiles
				) { item in
					cloudBackupDataCard(item, viewStore: viewStore)
				}
			} else {
				failureBox(message: L10n.RecoverProfileBackup.NoBackupsAvailable.ios)
			}
		}
	}

	@MainActor
	private func cloudBackupDataCard(
		_ item: SelectionItem<Profile.Header>,
		viewStore: ViewStoreOf<SelectBackup>
	) -> some View {
		let header = item.value
		let isVersionCompatible = header.isVersionCompatible()
		let lastDevice = header.lastUsedOnDevice.id == viewStore.thisDeviceID ? L10n.RecoverProfileBackup.thisDevice : header.lastUsedOnDevice.description

		let values: [String] = [
			L10n.RecoverProfileBackup.backupFrom(lastDevice),
			L10n.RecoverProfileBackup.lastModified(header.lastModified.formatted(date: .long, time: .omitted)),
			L10n.RecoverProfileBackup.numberOfAccounts(Int(header.contentHint.numberOfAccountsOnAllNetworksInTotal)),
			L10n.RecoverProfileBackup.numberOfPersonas(Int(header.contentHint.numberOfPersonasOnAllNetworksInTotal)),
		]

		return Card(.app.gray5) {
			HStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .small3) {
					ForEachStatic(values) {
						Text(markdown: $0, emphasizedColor: .app.gray2, emphasizedFont: .app.body2Link)
					}
					.foregroundColor(.secondaryText)
					.textStyle(.body2Regular)

					if !isVersionCompatible {
						Text(L10n.RecoverProfileBackup.incompatibleWalletDataLabel)
							.foregroundColor(.red)
							.textStyle(.body2HighImportance)
					}
				}

				Spacer(minLength: .small2)

				if isVersionCompatible {
					RadioButton(
						appearance: .dark,
						isSelected: item.isSelected
					)
				}
			}
			.padding(.top, .medium2)
			.padding(.horizontal, .medium1)
			.padding(.bottom, .medium3)
		}
		.disabled(!isVersionCompatible)
		.onTapGesture(perform: item.action)
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
			store: destinationStore.scope(state: \.inputEncryptionPassword, action: \.inputEncryptionPassword))
		{
			EncryptOrDecryptProfile.View(store: $0)
				.withNavigationBar {
					destinationStore.send(.dismiss)
				}
		}
	}

	private func recoverWalletWithoutProfileCoordinator(with destinationStore: PresentationStoreOf<SelectBackup.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore.scope(state: \.recoverWalletWithoutProfileCoordinator, action: \.recoverWalletWithoutProfileCoordinator))
		{
			RecoverWalletWithoutProfileCoordinator.View(store: $0)
		}
	}
}
