import FeaturePrelude

// MARK: - CameraPermission.View
extension CameraPermission {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CameraPermission>

		public init(store: StoreOf<CameraPermission>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ZStack {}
				.alert(
					store: store.scope(
						state: \.$permissionDeniedAlert,
						action: { .view(.permissionDeniedAlert($0)) }
					)
				)
				.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct CameraPermission_Preview: PreviewProvider {
	static var previews: some View {
		CameraPermission.View(
			store: .init(
				initialState: .previewValue,
				reducer: CameraPermission()
			)
		)
	}
}

extension CameraPermission.State {
	public static let previewValue: Self = .init()
}
#endif
