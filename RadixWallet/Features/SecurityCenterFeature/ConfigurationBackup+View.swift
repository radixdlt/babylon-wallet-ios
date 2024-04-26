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
						Text(L10n.ConfigurationBackup.heading)
							.foregroundStyle(.app.gray2)
							.textStyle(.body1Header)
							.padding(.bottom, .medium2)

						VStack(alignment: .leading, spacing: .medium3) {
							ForEach(viewStore.problems) { problem in
								ProblemView(problem: problem)
							}
						}
						.padding(.bottom, .medium3)

						let backupsEnabled = viewStore.binding(get: \.automatedBackupsEnabled) { .view(.toggleAutomatedBackups($0)) }
						AutomatedBackupView(
							backupsEnabled: backupsEnabled,
							lastBackedUp: viewStore.lastBackup,
							actionsRequired: viewStore.actionsRequired,
							outdatedBackupPresent: viewStore.outdatedBackupPresent,
							deleteOutdatedAction: { store.send(.view(.deleteOutdatedTapped)) }
						)
						.padding(.bottom, .medium1)

						Text(L10n.ConfigurationBackup.Manual.heading)
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
			.onAppear {
				store.send(.view(.onAppear))
			}
			.navigationBarTitleDisplayMode(.large)
			.navigationTitle(L10n.ConfigurationBackup.title)
		}
	}
}

// MARK: - ConfigurationBackup.AutomatedBackupView
extension ConfigurationBackup {
	struct ProblemView: SwiftUI.View {
		let problem: SecurityProblem

		var body: some SwiftUI.View {
			if let warning = warning(for: problem) {
				HStack(spacing: 0) {
					Image(.warningError)
						.renderingMode(.template)
						.resizable()
						.frame(.smallest)
						.padding(.trailing, .medium3)

					Text(warning)
						.multilineTextAlignment(.leading)
						.textStyle(.body2HighImportance)

					Spacer(minLength: 0)
				}
				.foregroundStyle(.app.alert)
				.padding(.vertical, .small1)
				.padding(.horizontal, .medium3)
				.background(.app.lightAlert)
				.roundedCorners(radius: .small1)
			}
		}

		func warning(for problem: SecurityProblem) -> String? {
			switch problem {
			case .problem3: nil
			case .problem5: L10n.ConfigurationBackup.problem5WarningIOS
			case .problem6: L10n.ConfigurationBackup.problem6Warning
			case .problem7: L10n.ConfigurationBackup.problem7Warning
			case .problem9: nil
			}
		}
	}

	struct AutomatedBackupView: SwiftUI.View {
		@Binding var backupsEnabled: Bool
		let lastBackedUp: Date?
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
										.foregroundStyle(.app.gray1)

									if backupsEnabled, let lastBackedUpString {
										Text(lastBackedUpString)
											.textStyle(.body2Regular)
											.foregroundStyle(.app.gray2)
									}
								}
							}
						}
						.padding(.top, .medium2)

						Divider()

						Text(L10n.ConfigurationBackup.Automated.text)
							.textStyle(.body1Regular)
							.foregroundStyle(.app.gray1)

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
								.foregroundStyle(.app.red1)

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

		private var lastBackedUpString: String? {
			guard let lastBackedUp else { return nil }
			print("••• making lastBackedUpString")
			return L10n.ConfigurationBackup.Automated.lastBackup(PastTimeFormatter.string(from: lastBackedUp))
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

							Text(title)
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
		let exportAction: () -> Void

		var body: some SwiftUI.View {
			Card {
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.ConfigurationBackup.Manual.text)
						.lineSpacing(0)
						.multilineTextAlignment(.leading)
						.textStyle(.body1Regular)
						.foregroundStyle(.app.gray1)
						.padding(.top, .medium2)
						.padding(.horizontal, .medium2)

					Button(L10n.ConfigurationBackup.Manual.exportButton, action: exportAction)
						.buttonStyle(.primaryRectangular(shouldExpand: true))
						.padding(.horizontal, .large2)

					WarningView(text: L10n.ConfigurationBackup.Manual.warning)
				}
			}
		}
	}

	struct WarningView: SwiftUI.View {
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

// MARK: - PastTimeFormatter
public enum PastTimeFormatter {
	public static func string(from date: Date) -> String {
		let dateString = { date.formatted(date: .numeric, time: .shortened) }

		let calendar = Calendar.current

		if calendar.isDateInToday(date) {
			let timeInterval = -date.timeIntervalSinceNow
			if timeInterval < 60 {
				return L10n.TimeFormatting.justNow
			}
			guard let relative = relativeFormatter.string(from: timeInterval) else {
				return dateString() // This should never happen
			}
			return L10n.TimeFormatting.ago(relative)

		} else if calendar.isDateInYesterday(date) {
			return L10n.TimeFormatting.yesterday
		} else {
			return dateString()
		}
	}

	private static let relativeFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		formatter.allowedUnits = [.minute, .hour, .day, .month, .year]
		formatter.zeroFormattingBehavior = .dropAll
		formatter.maximumUnitCount = 1
		return formatter
	}()
}

import CloudKit
import DependenciesAdditions

// MARK: - CloudBackupFeature
public struct CloudBackupFeature: FeatureReducer {
	public struct State: Hashable {
		var fetchingProfile: Bool = false
		var isUploadingProfileBackup: Bool = false
		var iCloudStatus: String?

		var lastBackupTime: String?
	}

	public enum ViewAction: Hashable, Sendable {
		case task
		case uploadProfile
		case addDummyAccount
		case checkAllOldProfiles
		case checkAllNewProfiles
		case deleteProfileTapped
		case logoutTapped
	}

	public enum InternalAction: Hashable, Sendable {
		case profileUploadResult(TaskResult<CKRecord>)
		case accountStatus(TaskResult<CKAccountStatus>)
		case cloudRecordStatus(TaskResult<CKRecord?>)
		case logout
	}

	@Dependency(\.cloudBackupClient) var cloudBackupClient
	@Dependency(\.userDefaults) var userDefaults

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in

				let status = await TaskResult { try await cloudBackupClient.checkAccountStatus() }
//				let cloudRecord = await TaskResult { try await cloudBackupClient.queryProfile(id) }

				await send(.internal(.accountStatus(status)))
//				await send(.internal(.cloudRecordStatus(cloudRecord)))
			}

		case .addDummyAccount:
//			state.profile.accounts.append(.init(name: "Acccount \(UUID().uuidString)"))

//			return uploadProfileBackup(&state)
			return .none

		case .uploadProfile:
			return uploadProfile(&state)

		case .checkAllOldProfiles:

			return .none

		case .checkAllNewProfiles:
			return .run { _ in
				let profiles = try await cloudBackupClient.queryAllProfiles()
				print("•• got \(profiles.count) profiles")
			} catch: { error, _ in
				print("•• got no profiles, only error: \(error)")
			}

		case .deleteProfileTapped:
			userDefaults.removeValue(forKey: "activeProfile")
			return .run { /* [id = profile.id] */ send in
//				try await cloudBackupClient.deleteProfile(id)
				await send(.internal(.logout))
			}

		case .logoutTapped:
			userDefaults.removeValue(forKey: "activeProfile")
			return .send(.internal(.logout))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountStatus(.success(status)):
			print("•• accountStatus received")
			switch status {
			case .couldNotDetermine:
				state.iCloudStatus = "Could not determine"
			case .available:
				state.iCloudStatus = "Available"
			case .restricted:
				state.iCloudStatus = "Retricted"
			case .noAccount:
				state.iCloudStatus = "No Account"
			case .temporarilyUnavailable:
				state.iCloudStatus = "Temporarily Unavailable"
			@unknown default:
				state.iCloudStatus = "Uknown"
			}
			return .none

		case .accountStatus:
			state.iCloudStatus = "Failed to determine"
			return .none

		case let .cloudRecordStatus(.success(.some(record))):
			state.lastBackupTime = record.modificationDate?.formatted() ?? "--"
			return .none

		case .cloudRecordStatus:
			state.lastBackupTime = "--"
			return .none

		case let .profileUploadResult(.success(record)):
			state.lastBackupTime = record.modificationDate?.formatted() ?? "--"
			state.isUploadingProfileBackup = false
			return .none

		case .profileUploadResult:
			state.isUploadingProfileBackup = false
			return .none

		case .logout:
			return .none
		}
	}

	private func uploadProfile(_ state: inout State) -> Effect<Action> {
		state.isUploadingProfileBackup = true
		return .run { send in
			let profile = await ProfileStore.shared.profile
			print("•• got profile: \(profile.id.uuidString)")
			let result: TaskResult<CKRecord> = await TaskResult {
				try await cloudBackupClient.uploadProfile(profile)
			}

			await send(.internal(.profileUploadResult(result)))
		}
	}
}

// MARK: CloudBackupFeature.View
extension CloudBackupFeature {
	public struct View: SwiftUI.View {
		let store: StoreOf<CloudBackupFeature>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack {
					HStack {
						Text("iCloud status: ")
						if let iCloudStatus = viewStore.iCloudStatus {
							Text(iCloudStatus)
						} else {
							ProgressView()
						}
						Spacer()
					}
					HStack {
						Text("Last Backup: ")
						if let lastBackupTime = viewStore.lastBackupTime, !viewStore.isUploadingProfileBackup {
							Text(lastBackupTime)
						} else {
							ProgressView()
						}
						Spacer()
					}
					if viewStore.fetchingProfile {
						VStack {
							ProgressView()
							Text("Fetching profile from iCloud")
						}
					} else {
						if viewStore.isUploadingProfileBackup {
							VStack {
								ProgressView()
								Text("Uploading backup to iCloud")
							}
						}

						//					List(store.profile.accounts) {
						//						Text($0.name)
						//					}

						Button("Add dummy account") {
							store.send(.view(.addDummyAccount))
						}
						.buttonStyle(.borderedProminent)

						Button("Upload profile") {
							store.send(.view(.uploadProfile))
						}
						.buttonStyle(.borderedProminent)

						Button("Check new profiles") {
							store.send(.view(.checkAllNewProfiles))
						}
						.buttonStyle(.borderedProminent)

						Button("Delete Profile") {
							store.send(.view(.deleteProfileTapped))
						}
						.buttonStyle(.borderedProminent)

						Button("Logout") {
							store.send(.view(.logoutTapped))
						}
						.buttonStyle(.borderedProminent)

						// Toggle("iCloud sync", isOn: .constant(true))
					}
				}
				.padding()
				.task {
					store.send(.view(.task))
				}
			}
		}
	}
}
