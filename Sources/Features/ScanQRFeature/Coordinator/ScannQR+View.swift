import FeaturePrelude

// MARK: - ScannQR.View
extension ScannQR {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScannQR>

		public init(store: StoreOf<ScannQR>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /ScannQR.State.cameraPermission,
					action: { ScannQR.Action.child(.cameraPermission($0)) },
					then: { CameraPermission.View(store: $0) }
				)
				CaseLet(
					state: /ScannQR.State.doScanQR,
					action: { ScannQR.Action.child(.doScanQR($0)) },
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
		ScannQR.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScannQR()
			)
		)
	}
}

extension ScannQR.State {
	public static let previewValue: Self = .init()
}
#endif
