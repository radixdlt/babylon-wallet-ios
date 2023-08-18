import FeaturePrelude

extension RestoreProfileFromBackupCoordinator.State {
	var viewState: RestoreProfileFromBackupCoordinator.ViewState {
		.init()
	}
}

// MARK: - RestoreProfileFromBackupCoordinator.View
extension RestoreProfileFromBackupCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RestoreProfileFromBackupCoordinator>

		public init(store: StoreOf<RestoreProfileFromBackupCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: RestoreProfileFromBackupCoordinator")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RestoreProfileFromBackup_Preview
struct RestoreProfileFromBackup_Preview: PreviewProvider {
	static var previews: some View {
		RestoreProfileFromBackupCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: RestoreProfileFromBackupCoordinator()
			)
		)
	}
}

extension RestoreProfileFromBackupCoordinator.State {
	public static let previewValue = Self()
}
#endif
