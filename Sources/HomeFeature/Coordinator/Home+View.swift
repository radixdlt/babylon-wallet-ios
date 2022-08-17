import Common
import ComposableArchitecture
import SwiftUI

public extension Home {
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

public extension Home.View {
	var body: some View {
		VStack {
			Home.Header.View(
				store: store.scope(
					state: \.header,
					action: Home.Action.header
				)
			)
			Spacer()
			Home.AggregatedValue.View(
				store: store.scope(
					state: \.aggregatedValue,
					action: Home.Action.aggregatedValue
				)
			)
			Spacer()
			WithViewStore(
				store.scope(
					state: ViewState.init,
					action: Home.Action.init
				)
			) { viewStore in
				createAccountButton {
					viewStore.send(.createAccountButtonTapped)
				}
			}
			Spacer()
			Home.VisitHub.View(
				store: store.scope(
					state: \.visitHub,
					action: Home.Action.visitHub
				)
			)
		}
		.padding(32)
	}
}

extension Home.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case createAccountButtonTapped
	}
}

extension Home.Action {
	init(action: Home.View.ViewAction) {
		switch action {
		case .createAccountButtonTapped:
			self = .internal(.user(.createAccountButtonTapped))
		}
	}
}

extension Home.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.State) {}
	}
}

private extension Home.View {
	func createAccountButton(action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(L10n.Home.createNewAccount)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.subhead)
				.padding(.horizontal, 40)
				.frame(height: 50)
				.background(Color.app.buttonBackgroundLight)
				.cornerRadius(6)
		}
	}
}

// MARK: - HomeView_Previews
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Home.View(
			store: .init(
				initialState: .init(),
				reducer: Home.reducer,
				environment: .placeholder
			)
		)
	}
}
