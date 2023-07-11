import FeaturePrelude

// MARK: - ScanQRCoordinator.View
extension ScanQRCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScanQRCoordinator>

		public init(store: StoreOf<ScanQRCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.step, action: { $0 })) { state in
				switch state {
				case .cameraPermission:
					CaseLet(
						state: /ScanQRCoordinator.State.Step.cameraPermission,
						action: { ScanQRCoordinator.Action.child(.cameraPermission($0)) },
						then: { CameraPermission.View(store: $0) }
					)
				case .scanQR:
					CaseLet(
						state: /ScanQRCoordinator.State.Step.scanQR,
						action: { ScanQRCoordinator.Action.child(.scanQR($0)) },
						then: { ScanQR.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ScannQR_Preview: PreviewProvider {
	static var previews: some View {
		ScanQRCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanQRCoordinator()
			)
		)
	}
}

extension ScanQRCoordinator.State {
	public static let previewValue: Self = .init(scanInstructions: "Preview")
}
#endif
