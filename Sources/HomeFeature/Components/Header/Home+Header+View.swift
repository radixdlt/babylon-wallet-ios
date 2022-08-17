import Common
import ComposableArchitecture
import SwiftUI

public extension Home.Header {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

public extension Home.Header.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.Header.Action.init
			)
		) { viewStore in
			VStack(alignment: .leading) {
				TitleView(
					shouldShowNotification: viewStore.state.hasNotification,
					settingsButtonAction: {
						viewStore.send(.settingsButtonTapped)
					}
				)
				subtitleView
			}
		}
	}
}

extension Home.Header.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case settingsButtonTapped
	}
}

extension Home.Header.Action {
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

		init(
			state: Home.Header.State
		) {
			hasNotification = state.hasNotification
		}
	}
}

private extension Home.Header.View {
	var subtitleView: some SwiftUI.View {
		HStack {
			Text(L10n.Home.Header.subtitle)
				.foregroundColor(.app.secondary)
				.font(.app.body)
		}
	}

	struct TitleView: SwiftUI.View {
		var shouldShowNotification: Bool
		let settingsButtonAction: () -> Void

		public var body: some View {
			HStack {
				Text(L10n.Home.Header.title)
					.foregroundColor(.app.buttonTextBlack)
					.font(.app.title)
				Spacer()
				SettingsButton(
					shouldShowNotification: shouldShowNotification,
					action: settingsButtonAction
				)
			}
		}
	}

	struct SettingsButton: SwiftUI.View {
		let shouldShowNotification: Bool
		let action: () -> Void

		public var body: some View {
			ZStack(alignment: .topTrailing) {
				// TODO: use swiftgen for assets
				Button(action: action) {
					Image("home-header-settings")
				}

				if shouldShowNotification {
					Circle()
						.foregroundColor(.app.notification)
						.frame(width: 5, height: 5)
				}
			}
		}
	}
}
