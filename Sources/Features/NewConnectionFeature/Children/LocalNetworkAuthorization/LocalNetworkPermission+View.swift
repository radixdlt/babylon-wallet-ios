import FeaturePrelude

// MARK: - LocalNetworkPermission.View
public extension LocalNetworkPermission {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<LocalNetworkPermission>

		public init(store: StoreOf<LocalNetworkPermission>) {
			self.store = store
		}
	}
}

public extension LocalNetworkPermission.View {
	var body: some View {
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

// MARK: - ScanQR_Preview
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
