import Common
import ComposableArchitecture
import SwiftUI

public extension Home {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Home.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
		var hasNotification: Bool
		init(state: Home.State) {
			hasNotification = state.hasNotification
		}
	}
}

internal extension Home.Coordinator {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case settingsButtonTapped
	}
}

internal extension Home.Action {
	init(action: Home.Coordinator.ViewAction) {
		switch action {
		case .settingsButtonTapped:
			self = .internal(.user(.settingsButtonTapped))
		}
	}
}

public extension Home.Coordinator {
	// MARK: Body
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.Action.init
			)
		) { _ in
			VStack(alignment: .leading, spacing: 10) {
				Text("")
				//                Home.Header.TitleView(action: { viewStore.send(.settingsButtonTapped) },
//				          shouldShowNotification: viewStore.state.hasNotification)
//					.padding(EdgeInsets(top: 57, leading: 31, bottom: 0, trailing: 31))
				//                Home.Header.subtitleView
//					.padding(EdgeInsets(top: 0, leading: 29, bottom: 0, trailing: 29))
			}
		}
	}
}

/*
private extension Home.Coordinator {
	var subtitleView: some View {
		GeometryReader { proxy in
			Text(L10n.Home.Wallet.subtitle)
				.frame(width: proxy.size.width * 0.7)
				.font(.app.body)
				.foregroundColor(.app.secondary)
		}
	}

	struct TitleView: View {
		let action: () -> Void
		var shouldShowNotification: Bool

		var body: some View {
			HStack {
				Text(L10n.Home.Wallet.title)
					.font(.app.title)
				Spacer()
				SettingsButton(action: action, shouldShowNotification: shouldShowNotification)
			}
		}
	}

	struct SettingsButton: View {
		let action: () -> Void
		var shouldShowNotification: Bool

		var body: some View {
			ZStack(alignment: .topTrailing) {
				Button(action: {
					action()
				}, label: {
					Image("home-settings")
				})

				if shouldShowNotification {
					Circle()
						.foregroundColor(.app.notification)
						.frame(width: 5, height: 5)
				}
			}
		}
	}
}
*/

// MARK: - HomeView_Previews
#if DEBUG
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Home.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Home.reducer,
				environment: .init()
			)
		)
	}
}
#endif // DEBUG
