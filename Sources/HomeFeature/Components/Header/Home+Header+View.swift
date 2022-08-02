import Common
import ComposableArchitecture
import SwiftUI

public extension Home.Header {
	struct View: SwiftUI.View {
		let store: Store<State, Action>

		public var body: some SwiftUI.View {
//			WithViewStore(
//				store.scope(
//					state: ViewState.init,
//					action: Home.Header.Action.init
//				)
//			) { viewStore in
//				VStack(alignment: .leading, spacing: 10) {
//					TitleView(action: { viewStore.send(.settingsButtonTapped) },
//					          shouldShowNotification: viewStore.state.hasNotification)
//						.padding(EdgeInsets(top: 57, leading: 31, bottom: 0, trailing: 31))
//					subtitleView
//						.padding(EdgeInsets(top: 0, leading: 29, bottom: 0, trailing: 29))
//				}
//			}
			Text("NO HEADER")
		}
	}
}

internal extension Home.Header.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case settingsButtonTapped
	}
}

internal extension Home.Header.Action {
	init(action _: Home.Header.View.ViewAction) {
//		switch action {
//		case .settingsButtonTapped:
//			self = .internal(.user(.settingsButtonTapped))
//		}
		fatalError()
	}
}

extension Home.Header.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var hasNotification: Bool
		init(state: Home.Header.State) {
			hasNotification = state.hasNotification
		}
	}
}

private extension Home.Header.View {
	var subtitleView: some SwiftUI.View {
		GeometryReader { proxy in
			Text(L10n.Home.Wallet.subtitle)
				.frame(width: proxy.size.width * 0.7)
				.font(.app.body)
				.foregroundColor(.app.secondary)
		}
	}

	struct TitleView: SwiftUI.View {
		let action: () -> Void
		var shouldShowNotification: Bool

		public var body: some SwiftUI.View {
			HStack {
				Text(L10n.Home.Wallet.title)
					.font(.app.title)
				Spacer()
				SettingsButton(action: action, shouldShowNotification: shouldShowNotification)
			}
		}
	}

	struct SettingsButton: SwiftUI.View {
		let action: () -> Void
		var shouldShowNotification: Bool

		public var body: some SwiftUI.View {
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
