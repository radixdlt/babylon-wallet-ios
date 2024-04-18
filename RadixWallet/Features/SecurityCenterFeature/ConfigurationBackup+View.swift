import ComposableArchitecture
import SwiftUI

// MARK: - ConfigurationBackup.View
extension ConfigurationBackup {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConfigurationBackup>

		public init(store: StoreOf<ConfigurationBackup>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .zero) {
						Text(L10n.ConfigurationBackup.subtitle)
							.foregroundStyle(.app.gray2)
							.textStyle(.body1Header)
							.padding(.bottom, .medium2)

						let backupsEnabled = viewStore.binding(get: \.automatedBackupsEnabled) { .view(.toggleAutomatedBackups($0)) }
						AutomatedBackupView(
							backupsEnabled: backupsEnabled,
							loggedInName: viewStore.loggedInName,
							actionsRequired: [.personas],
							disconnectAction: { store.send(.view(.disconnectTapped)) }
						)
						.padding(.bottom, .medium1)

						Text(L10n.ConfigurationBackup.ManualBackup.heading)
							.foregroundStyle(.app.gray2)
							.textStyle(.body1Header)
							.padding(.bottom, .medium2)

						ManualBackupView {
							store.send(.view(.exportTapped))
						}
					}
					.padding(.top, .small2)
					.padding(.horizontal, .medium2)
				}
			}
			.navigationBarTitleDisplayMode(.large)
			.navigationTitle(L10n.ConfigurationBackup.title)
		}
	}
}

// MARK: - ConfigurationBackup.AutomatedBackupView
extension ConfigurationBackup {
	struct AutomatedBackupView: SwiftUI.View {
		@Binding var backupsEnabled: Bool
		let loggedInName: String?
		let actionsRequired: [Item]
		let disconnectAction: () -> Void

		var body: some SwiftUI.View {
			Card {
				VStack(spacing: 0) {
					VStack(alignment: .leading, spacing: .medium3) {
						HStack(spacing: .medium3) {
							Image(.cloud)

							Toggle(isOn: $backupsEnabled) {
								VStack(alignment: .leading, spacing: .small3) {
									Text(L10n.ConfigurationBackup.backupsToggleICloud)
										.multilineTextAlignment(.leading)
										.textStyle(.body1Header)
										.foregroundStyle(.app.gray1)

									Text(L10n.ConfigurationBackup.backupsUpdate("3 min"))
										.textStyle(.body2Regular)
										.foregroundStyle(.app.gray2)
								}
							}
						}
						.padding(.top, .medium2)

						Divider()

						Text(L10n.ConfigurationBackup.automatedBackupsToggle)
							.textStyle(.body1Regular)
							.foregroundStyle(.app.gray1)

						VStack(spacing: .small1) {
							ForEach(Item.allCases, id: \.self) { item in
								ItemView(item: item, actionRequired: actionsRequired.contains(item))
							}
						}

						if let loggedInName {
							Divider()

							HStack(spacing: 0) {
								VStack(alignment: .leading, spacing: .small2) {
									Text(L10n.ConfigurationBackup.loggedInAsHeading)
										.textStyle(.body2Regular)
										.foregroundStyle(.app.gray2)

									Text(loggedInName)
										.textStyle(.body1Regular)
										.foregroundStyle(.app.gray1)
								}

								Spacer(minLength: .small2)

								Button(L10n.ConfigurationBackup.disconnectButton, action: disconnectAction)
									.buttonStyle(.blueText)
							}
						}
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .small1)

					BottomView(text: L10n.ConfigurationBackup.automatedBackupsWarning)
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
							SecurityCenter.StatusIcon(actionRequired: actionRequired)
								.padding(.trailing, .small3)

							Text(heading)
								.textStyle(.body2HighImportance)
								.foregroundStyle(actionRequired ? .app.alert : .app.green1)

							Spacer(minLength: 0)

							Image(expanded ? .chevronUp : .chevronDown)
						}
					}

					if expanded {
						Text(subtitle)
							.multilineTextAlignment(.leading)
							.lineSpacing(0)
							.textStyle(.body1Regular)
							.foregroundStyle(.app.gray1)
					}
				}
				.clipped()
			}

			var heading: String {
				switch item {
				case .accounts: L10n.ConfigurationBackup.accountsItem
				case .personas: L10n.ConfigurationBackup.personasItem
				case .securityFactors: L10n.ConfigurationBackup.securityFactorsItem
				case .walletSettings: L10n.ConfigurationBackup.walletSettingsItem
				}
			}

			var subtitle: String {
				switch item {
				case .accounts: L10n.ConfigurationBackup.accountsSubtitle
				case .personas: L10n.ConfigurationBackup.personasSubtitle
				case .securityFactors: L10n.ConfigurationBackup.securityFactorsSubtitle
				case .walletSettings: L10n.ConfigurationBackup.walletSettingsSubtitle
				}
			}
		}
	}

	struct ManualBackupView: SwiftUI.View {
		let exportAction: () -> Void

		var body: some SwiftUI.View {
			Card {
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.ConfigurationBackup.ManualBackup.subtitle)
						.lineSpacing(0)
						.multilineTextAlignment(.leading)
						.textStyle(.body1Regular)
						.foregroundStyle(.app.gray1)
						.padding(.top, .medium2)
						.padding(.horizontal, .medium2)

					Button(L10n.ConfigurationBackup.ManualBackup.exportButton, action: exportAction)
						.buttonStyle(.primaryRectangular(shouldExpand: true))
						.padding(.horizontal, .large2)

					BottomView(text: L10n.ConfigurationBackup.ManualBackup.warning)
				}
			}
		}
	}

	struct BottomView: SwiftUI.View {
		let text: String

		var body: some SwiftUI.View {
			HStack(spacing: 0) {
				Image(.warningError)
					.resizable()
					.renderingMode(.template)
					.foregroundStyle(.app.gray1)
					.frame(.smallest)
					.padding(.trailing, .medium3)

				Text(text)
					.multilineTextAlignment(.leading)
					.lineSpacing(0)
					.textStyle(.body1Regular)
					.foregroundStyle(.app.gray1)

				Spacer(minLength: 0)
			}
			.padding(.horizontal, .medium2)
			.padding(.vertical, .medium3)
			.background(.app.gray5)
		}
	}
}
