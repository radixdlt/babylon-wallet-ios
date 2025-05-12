import ComposableArchitecture
import SwiftUI

extension ConfigurationBackup.State {
	var lastCloudBackupString: String? {
		if let lastCloudBackup, lastCloudBackup.isCurrent, lastCloudBackup.result.succeeded {
			nil
		} else {
			L10n.ConfigurationBackup.Automated.lastBackup(
				lastCloudBackup?.result.lastSuccess.map { RadixDateFormatter.string(from: $0) } ?? L10n.Common.none
			)
		}
	}

	var lastManualBackupString: String? {
		guard let lastManualBackup else { return nil }
		return L10n.ConfigurationBackup.Automated.lastBackup(RadixDateFormatter.string(from: lastManualBackup))
	}
}

// MARK: - ConfigurationBackup.View
extension ConfigurationBackup {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConfigurationBackup>

		init(store: StoreOf<ConfigurationBackup>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .zero) {
						Text(L10n.ConfigurationBackup.heading)
							.foregroundStyle(Color.secondaryText)
							.textStyle(.body1Header)
							.padding(.bottom, .medium2)

						VStack(alignment: .leading, spacing: .medium3) {
							ForEach(viewStore.problems) { problem in
								ProblemView(problem: problem)
							}
						}
						.padding(.bottom, .medium3)

						let backupsEnabled = viewStore.binding(get: \.cloudBackupsEnabled) { .view(.cloudBackupsToggled($0)) }
						AutomatedBackupView(
							backupsEnabled: backupsEnabled,
							lastBackupString: viewStore.lastCloudBackupString,
							actionsRequired: viewStore.actionsRequired,
							outdatedBackupPresent: viewStore.outdatedBackupPresent,
							deleteOutdatedAction: { store.send(.view(.deleteOutdatedTapped)) }
						)
						.padding(.bottom, .medium1)

						Text(L10n.ConfigurationBackup.Manual.heading)
							.foregroundStyle(Color.secondaryText)
							.textStyle(.body1Header)
							.padding(.bottom, .medium2)

						ManualBackupView(lastBackupString: viewStore.lastManualBackupString) {
							store.send(.view(.exportTapped))
						}
					}
					.padding(.top, .small2)
					.padding(.horizontal, .medium2)
				}
				.exportFileSheet(store: store, exportable: viewStore.exportable)
			}
			.background(Color.secondaryBackground)
			.onAppear {
				store.send(.view(.didAppear))
			}
			.radixToolbar(title: L10n.ConfigurationBackup.title)
			.destinations(with: store)
		}
	}
}

private extension StoreOf<ConfigurationBackup> {
	var destination: PresentationStoreOf<ConfigurationBackup.Destination> {
		func scopeState(state: State) -> PresentationState<ConfigurationBackup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ConfigurationBackup>) -> some View {
		let destinationStore = store.destination
		return encryptProfileOrNotAlert(with: destinationStore)
			.encryptionPasswordSheet(with: destinationStore)
	}

	private func encryptProfileOrNotAlert(with destinationStore: PresentationStoreOf<ConfigurationBackup.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.encryptProfileOrNot, action: \.encryptProfileOrNot))
	}

	private func encryptionPasswordSheet(with destinationStore: PresentationStoreOf<ConfigurationBackup.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.encryptionPassword, action: \.encryptionPassword)) {
			EncryptOrDecryptProfile.View(store: $0)
				.withNavigationBar {
					destinationStore.send(.dismiss)
				}
		}
	}

	func exportFileSheet(store: StoreOf<ConfigurationBackup>, exportable: ConfigurationBackup.Exportable?) -> some View {
		fileExporter(
			isPresented: .init(get: { exportable != nil }, set: { store.send(.view(.showFileExporter($0))) }),
			document: exportable?.file,
			contentType: .profile,
			// Need to disable, since broken in swiftformat 0.52.7
			// swiftformat:disable redundantClosure
			defaultFilename: {
				switch exportable?.file {
				case .plaintext, .none: String.filenameProfileNotEncrypted
				case .encrypted: String.filenameProfileEncrypted
				}
			}(),
			// swiftformat:enable redundantClosure
			onCompletion: { store.send(.view(.profileExportResult($0.mapError { $0 as NSError }, exportable?.profile))) }
		)
	}
}

// MARK: - ConfigurationBackup.AutomatedBackupView
extension ConfigurationBackup {
	struct ProblemView: SwiftUI.View {
		let problem: SecurityProblem

		var body: some SwiftUI.View {
			if let text = problem.configurationBackup {
				HStack(spacing: 0) {
					Image(.error)
						.padding(.trailing, .medium3)

					Text(text)
						.multilineTextAlignment(.leading)
						.textStyle(.body2HighImportance)

					Spacer(minLength: 0)
				}
				.foregroundStyle(.warning)
				.padding(.vertical, .small1)
				.padding(.horizontal, .medium3)
				.background(.warningSecondary)
				.roundedCorners(radius: .small1)
			}
		}
	}

	struct AutomatedBackupView: SwiftUI.View {
		@Binding var backupsEnabled: Bool
		let lastBackupString: String?
		let actionsRequired: [Item]
		let outdatedBackupPresent: Bool
		let deleteOutdatedAction: () -> Void

		var body: some SwiftUI.View {
			Card {
				VStack(spacing: 0) {
					VStack(alignment: .leading, spacing: .medium3) {
						HStack(spacing: .medium3) {
							Image(.cloud)

							Toggle(isOn: $backupsEnabled) {
								VStack(alignment: .leading, spacing: .small3) {
									Text(L10n.ConfigurationBackup.Automated.toggleIOS)
										.multilineTextAlignment(.leading)
										.textStyle(.body1Header)
										.foregroundStyle(Color.primaryText)

									if let lastBackupString {
										Text(lastBackupString)
											.textStyle(.body2Regular)
											.foregroundStyle(Color.secondaryText)
									}
								}
							}
							.tint(.toggleActive)
						}
						.padding(.top, .medium2)

						Divider()

						Text(L10n.ConfigurationBackup.Automated.text)
							.textStyle(.body1Regular)
							.foregroundStyle(Color.primaryText)

						VStack(spacing: .small1) {
							ForEach(Item.allCases, id: \.self) { item in
								ItemView(item: item, actionRequired: actionsRequired.contains(item))
							}
						}
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .small1)

					if outdatedBackupPresent {
						Divider()

						HStack(spacing: 0) {
							Image(.folder)
								.padding(.trailing, .medium3)

							Text(L10n.ConfigurationBackup.Automated.outdatedBackupIOS)
								.multilineTextAlignment(.leading)
								.lineSpacing(0)
								.textStyle(.body1Link)
								.foregroundStyle(.error)

							Spacer(minLength: .small2)

							Button(L10n.ConfigurationBackup.Automated.deleteOutdatedBackupIOS, action: deleteOutdatedAction)
								.buttonStyle(.blueText)
						}
						.padding(.horizontal, .medium2)
						.padding(.vertical, .medium3)
					}

					WarningView(text: L10n.ConfigurationBackup.Automated.warning)
				}
			}
		}

		struct ItemView: SwiftUI.View {
			@SwiftUI.State private var expanded: Bool = false
			let item: Item
			let actionRequired: Bool

			var body: some SwiftUI.View {
				VStack(alignment: .leading, spacing: .small3) {
					Button {
						withAnimation(.default) {
							expanded.toggle()
						}
					} label: {
						HStack(spacing: .zero) {
							let style: Color = actionRequired ? .warning : .app.green1
							Image(actionRequired ? .error : .checkCircle)
								.padding(.trailing, .small3)
								.foregroundStyle(style)

							Text(title)
								.textStyle(.body2HighImportance)
								.foregroundStyle(style)

							Spacer(minLength: 0)

							Image(expanded ? .chevronUp : .chevronDown)
						}
					}

					if expanded {
						Text(subtitle)
							.multilineTextAlignment(.leading)
							.lineSpacing(0)
							.textStyle(.body2Regular)
							.foregroundStyle(Color.secondaryText)
					}
				}
				.clipped()
			}

			var title: String {
				switch item {
				case .accounts: L10n.ConfigurationBackup.Automated.accountsItemTitle
				case .personas: L10n.ConfigurationBackup.Automated.personasItemTitle
				case .securityFactors: L10n.ConfigurationBackup.Automated.securityFactorsItemTitle
				case .walletSettings: L10n.ConfigurationBackup.Automated.walletSettingsItemTitle
				}
			}

			var subtitle: String {
				switch item {
				case .accounts: L10n.ConfigurationBackup.Automated.accountsItemSubtitle
				case .personas: L10n.ConfigurationBackup.Automated.personasItemSubtitle
				case .securityFactors: L10n.ConfigurationBackup.Automated.securityFactorsItemSubtitle
				case .walletSettings: L10n.ConfigurationBackup.Automated.walletSettingsItemSubtitle
				}
			}
		}
	}

	struct ManualBackupView: SwiftUI.View {
		let lastBackupString: String?
		let exportAction: () -> Void

		var body: some SwiftUI.View {
			Card {
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.ConfigurationBackup.Manual.text)
						.lineSpacing(0)
						.multilineTextAlignment(.leading)
						.textStyle(.body1Regular)
						.foregroundStyle(Color.primaryText)
						.padding(.top, .medium2)
						.padding(.horizontal, .medium2)

					Button(L10n.ConfigurationBackup.Manual.exportButton, action: exportAction)
						.buttonStyle(.primaryRectangular(shouldExpand: true))
						.padding(.horizontal, .large2)

					if let lastBackupString {
						Text(lastBackupString)
							.textStyle(.body2Regular)
							.foregroundStyle(Color.secondaryText)
							.padding(.horizontal, .medium2)
					}

					WarningView(text: L10n.ConfigurationBackup.Manual.warning)
				}
			}
		}
	}

	struct WarningView: SwiftUI.View {
		let text: String

		var body: some SwiftUI.View {
			HStack(spacing: 0) {
				Image(.error)
					.foregroundStyle(Color.primaryText)
					.padding(.trailing, .medium3)

				Text(text)
					.multilineTextAlignment(.leading)
					.lineSpacing(0)
					.textStyle(.body1Regular)
					.foregroundStyle(Color.primaryText)

				Spacer(minLength: 0)
			}
			.padding(.horizontal, .medium2)
			.padding(.vertical, .medium3)
			.background(Color.tertiaryBackground)
		}
	}
}
