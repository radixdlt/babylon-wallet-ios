import FeaturePrelude

// MARK: - LocalNetworkPermission.View
extension LocalNetworkPermission {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<LocalNetworkPermission>

		public init(store: StoreOf<LocalNetworkPermission>) {
			self.store = store
		}
	}
}

extension LocalNetworkPermission.View {
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

// MARK: - LocalNetworkPermission.View.ViewState
extension LocalNetworkPermission.View {
	struct ViewState: Equatable {
		init(state: LocalNetworkPermission.State) {}
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
#endif
