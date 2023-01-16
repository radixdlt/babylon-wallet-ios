import FeaturePrelude

// MARK: - AccountDetails.Transfer.View
public extension AccountDetails.Transfer {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension AccountDetails.Transfer.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Implement: Transfer")
						.background(Color.yellow)
						.foregroundColor(.red)
					Button(
						action: { viewStore.send(.dismissTransferButtonTapped) },
						label: { Text("Dismiss Transfer") }
					)
				}
			}
		}
	}
}

// MARK: - AccountDetails.Transfer.View.ViewState
extension AccountDetails.Transfer.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.Transfer.State) {}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Transfer_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.Transfer.View(
			store: .init(
				initialState: .init(),
				reducer: AccountDetails.Transfer()
			)
		)
	}
}
#endif
