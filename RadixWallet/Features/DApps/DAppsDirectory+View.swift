import SwiftUI

// MARK: - DAppsDirectory.View
extension DAppsDirectory {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<DAppsDirectory>
		@SwiftUI.State var selection: Int = 0

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					headerView()
					if selection == 0 {
						AllDapps.View(store: store.scope(state: \.allDapps, action: \.child.allDapps))
					} else {
						AuthorizedDappsFeature.View(store: store.scope(state: \.approvedDapps, action: \.child.approvedDapps))
					}
				}
				.background(.primaryBackground)
			}
		}

		@ViewBuilder
		func headerView() -> some SwiftUI.View {
			VStack {
				HStack {
					Spacer()
					Text(L10n.DappDirectory.title)
						.foregroundColor(Color.primaryText)
						.textStyle(.body1Header)
					Spacer()
				}
				.padding(.horizontal, .medium3)

				Picker("", selection: $selection) {
					Text("All Dapps")
						.tag(0)
					Text("Approved Dapps")
						.tag(1)
				}
				.tint(.primaryBackground)
				.pickerStyle(.segmented)
				.padding(.horizontal, .medium3)
			}
			.padding(.top, .small3)
			.padding(.bottom, .small1)
			.background(.primaryBackground)
		}
	}
}

extension DAppsDirectoryClient.DApp.Category {
	var title: String {
		switch self {
		case .defi:
			"DeFi"
		case .dao:
			"DAO"
		case .utility:
			"Utility"
		case .meme:
			"Meme"
		case .nft:
			"NFT"
		case .other:
			"Other"
		}
	}
}
