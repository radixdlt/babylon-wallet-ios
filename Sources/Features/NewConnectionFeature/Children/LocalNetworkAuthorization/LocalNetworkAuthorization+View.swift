import ComposableArchitecture
import Resources
import SwiftUI

// MARK: - LocalNetworkAuthorization.View
public extension LocalNetworkAuthorization {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<LocalNetworkAuthorization>

		public init(store: StoreOf<LocalNetworkAuthorization>) {
			self.store = store
		}
	}
}

public extension LocalNetworkAuthorization.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			Color.white
				.alert(
					store.scope(
						state: \.authorizationDeniedAlert,
						action: { .view(.authorizationDeniedAlert($0)) }
					),
					dismiss: .dismissed
				)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - LocalNetworkAuthorization.View.ViewState
extension LocalNetworkAuthorization.View {
	struct ViewState: Equatable {
		init(state: LocalNetworkAuthorization.State) {}
	}
}

#if DEBUG

// MARK: - ScanQR_Preview
struct LocalNetworkAuthorization_Preview: PreviewProvider {
	static var previews: some View {
		LocalNetworkAuthorization.View(
			store: .init(
				initialState: .previewValue,
				reducer: LocalNetworkAuthorization()
			)
		)
	}
}
#endif
