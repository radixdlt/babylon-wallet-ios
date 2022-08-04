import Common
import ComposableArchitecture
import SwiftUI

public extension Home.Header {
	struct View: SwiftUI.View {
		let store: Store<State, Action>

		public var body: some SwiftUI.View {
			WithViewStore(
				store.scope(
					state: ViewState.init,
					action: Home.Header.Action.init
				)
			) { viewStore in
				VStack {
					TitleView(
						shouldShowNotification: viewStore.state.hasNotification,
						settingsButtonTappedAction: { viewStore.send(.settingsButtonTapped) }
					)
				}
			}
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
	init(action: Home.Header.View.ViewAction) {
		switch action {
		case .settingsButtonTapped:
			self = .internal(.user(.settingsButtonTapped))
		}
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
		HStack {
			Text(L10n.Home.Wallet.subtitle)
				.font(.app.body)
				.foregroundColor(.app.secondary)
			Spacer(minLength: 88)
		}
	}

	struct TitleView: SwiftUI.View {
		var shouldShowNotification: Bool
		let settingsButtonTappedAction: () -> Void

		public var body: some SwiftUI.View {
			HStack {
				Text(L10n.Home.Wallet.title)
					.font(.app.title)
				Spacer()
				SettingsButton(action: settingsButtonTappedAction, shouldShowNotification: shouldShowNotification)
			}
		}
	}

	struct SettingsButton: SwiftUI.View {
		let action: () -> Void
		let shouldShowNotification: Bool

		public var body: some SwiftUI.View {
			ZStack(alignment: .topTrailing) {
				Button(action: action, label: { Image("home-settings") })

				if shouldShowNotification {
					Circle()
						.foregroundColor(.app.notification)
						.frame(width: 5, height: 5)
				}
			}
		}
	}
}
