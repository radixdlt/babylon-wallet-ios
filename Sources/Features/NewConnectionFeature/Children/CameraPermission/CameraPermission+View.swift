import FeaturePrelude

// MARK: - CameraPermission.View
extension CameraPermission {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CameraPermission>

		public init(store: StoreOf<CameraPermission>) {
			self.store = store
		}
	}
}

extension CameraPermission.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ZStack {}
				.alert(
					store.scope(
						state: \.permissionDeniedAlert,
						action: { .view(.permissionDeniedAlert($0)) }
					),
					dismiss: .dismissed
				)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - CameraPermission.View.ViewState
extension CameraPermission.View {
	struct ViewState: Equatable {
		init(state: CameraPermission.State) {}
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
#endif
