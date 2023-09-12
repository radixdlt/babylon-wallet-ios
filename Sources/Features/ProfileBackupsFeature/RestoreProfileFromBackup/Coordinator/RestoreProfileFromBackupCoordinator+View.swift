import FeaturePrelude

// MARK: - RestoreProfileFromBackupCoordinator.View
extension RestoreProfileFromBackupCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RestoreProfileFromBackupCoordinator>

		public init(store: StoreOf<RestoreProfileFromBackupCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				path(for: store.scope(state: \.root, action: { .child(.root($0)) }))
			} destination: {
				path(for: $0)
			}
		}

		func path(
			for store: StoreOf<RestoreProfileFromBackupCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .selectBackup:
					CaseLet(
						state: /RestoreProfileFromBackupCoordinator.Path.State.selectBackup,
						action: RestoreProfileFromBackupCoordinator.Path.Action.selectBackup,
						then: { SelectBackup.View(store: $0) }
					)
				case .importMnemonicsFlow:
					CaseLet(
						state: /RestoreProfileFromBackupCoordinator.Path.State.importMnemonicsFlow,
						action: RestoreProfileFromBackupCoordinator.Path.Action.importMnemonicsFlow,
						then: { ImportMnemonicsFlowCoordinator.View(store: $0) }
					)
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - RestoreProfileFromBackup_Preview
// struct RestoreProfileFromBackup_Preview: PreviewProvider {
//	static var previews: some View {
//		RestoreProfileFromBackupCoordinator.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: RestoreProfileFromBackupCoordinator.init
//			)
//		)
//	}
// }
//
// extension RestoreProfileFromBackupCoordinator.State {
//	public static let previewValue = Self()
// }
// #endif
