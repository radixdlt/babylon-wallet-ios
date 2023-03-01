import FeaturePrelude

// MARK: - LocalNetworkPermission.View
extension LocalNetworkPermission {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<LocalNetworkPermission>

		public init(store: StoreOf<LocalNetworkPermission>) {
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

extension LocalNetworkPermission {
	struct Preview: PreviewProvider {
		static var previews: some SwiftUI.View {
			LocalNetworkPermission.View(
				store: .init(
					initialState: .previewValue,
					reducer: LocalNetworkPermission()
				)
			)
		}
	}
}

extension LocalNetworkPermission.State {
	public static let previewValue: Self = .init()
}
#endif
