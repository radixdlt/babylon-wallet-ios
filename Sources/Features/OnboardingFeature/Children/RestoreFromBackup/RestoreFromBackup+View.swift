import FeaturePrelude
import InspectProfileFeature
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
					VStack(spacing: .medium1) {
						Text("Select Backup Profile")
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						// TODO: Display the loading
						if let backupProfiles = viewStore.backupProfiles {
							ForEach(backupProfiles) { profile in
								Card {
									HStack {
										VStack(alignment: .leading, spacing: 0) {
											Text("Creating Device: \(profile.header.creatingDevice.rawValue)")
												.foregroundColor(.app.gray1)
												.textStyle(.secondaryHeader)
											Text("Creation Date: \(formatDate(profile.header.creationDate))")
												.foregroundColor(.app.gray2)
												.textStyle(.body2Regular)
											Text("Last Modified Date: \(formatDate(profile.header.lastModified))")
												.foregroundColor(.app.gray2)
												.textStyle(.body2Regular)
										}
										Spacer(minLength: 0)
										Image(asset: AssetResource.chevronRight)
									}
									.padding(.medium2)
									//   .background(Color.app.gray5)
									// .cornerRadius(.small1)
								}
								.onTapGesture {
									viewStore.send(.selectedProfile(profile))
								}
							}
						} else {
							Text("No backup profiles")
						}
					}.padding([.horizontal, .bottom], .medium1)
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.sheet(item: viewStore.binding(get: {
					$0.selectedProfile
				}, send: { _ in
					.dismissedSelectedProfile
				})) { profile in
					VStack {
						ProfileView(
							profile: profile,
							// Sorry about this, hacky hacky hack. But it is only for debugging and we are short on time..
							secureStorageClient: SecureStorageClient.liveValue
						)

						Button("Import") {
							viewStore.send(.importProfile(profile))
						}
						.buttonStyle(.primaryRectangular)
						.padding(.horizontal, .medium3)
					}.padding(.vertical, .medium3)
				}
			}
		}
	}

	func formatDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "d MMM YYY"
		return formatter.string(from: date)
	}
}
