import ComposableArchitecture
import SwiftUI

// MARK: - LocalNetworkPermission.View
extension LocalNetworkPermission {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<LocalNetworkPermission>

		init(store: StoreOf<LocalNetworkPermission>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			ZStack {}
				.background(.red)
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

extension LocalNetworkPermission {
	struct Preview: PreviewProvider {
		static var previews: some SwiftUI.View {
			LocalNetworkPermission.View(
				store: .init(
					initialState: .previewValue,
					reducer: LocalNetworkPermission.init
				)
			)
		}
	}
}

extension LocalNetworkPermission.State {
	static let previewValue: Self = .init()
}
#endif
