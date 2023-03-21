import FeaturePrelude

// MARK: - ScanQR.View
extension ScanQR {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScanQR>

		public init(store: StoreOf<ScanQR>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /ScanQR.State.cameraPermission,
					action: { ScanQR.Action.child(.cameraPermission($0)) },
					then: { CameraPermission.View(store: $0) }
				)
				CaseLet(
					state: /ScanQR.State.doScanQR,
					action: { ScanQR.Action.child(.doScanQR($0)) },
					then: { DoScanQR.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ScannQR_Preview: PreviewProvider {
	static var previews: some View {
		ScanQR.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanQR()
			)
		)
	}
}

extension ScanQR.State {
	public static let previewValue: Self = .init()
}
#endif
