import ComposableArchitecture
import SwiftUI

// MARK: - CameraPermission.View
extension CameraPermission {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CameraPermission>

		init(store: StoreOf<CameraPermission>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			ZStack {}
				.alert(
					store: store.scope(
						state: \.$permissionDeniedAlert,
						action: { .view(.permissionDeniedAlert($0)) }
					)
				)
				.onAppear { store.send(.view(.appeared)) }
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct CameraPermission_Preview: PreviewProvider {
	static var previews: some View {
		CameraPermission.View(
			store: .init(
				initialState: .previewValue,
				reducer: CameraPermission.init
			)
		)
	}
}

extension CameraPermission.State {
	static let previewValue: Self = .init()
}
#endif
