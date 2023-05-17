import FeaturePrelude

extension ProfileBackups.State {
	var viewState: ProfileBackups.ViewState {
		.init()
	}
}

// MARK: - ScanQR.View
extension ProfileBackups {
	public struct ViewState: Equatable {
		// TODO: Configure
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ProfileBackups>

		public init(store: StoreOf<ProfileBackups>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { _ in
				Text("TO BE IMPLEMENTED").textStyle(.sheetTitle)
			}
			.navigationTitle(L10n.Settings.backups)
		}
	}
}
