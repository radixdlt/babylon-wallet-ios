import Common
import ComposableArchitecture
import SwiftUI

public extension Home.VisitHub {
	struct View: SwiftUI.View {
		let store: Store<State, Action>

		public var body: some SwiftUI.View {
			WithViewStore(
				store.scope(
					state: ViewState.init,
					action: Home.VisitHub.Action.init
				)
			) { viewStore in
				VStack {
					title
					visitHubButton {
						viewStore.send(.visitHubButtonTapped)
					}
				}
				.background(Color.app.buttonBackgroundDark)
				.cornerRadius(6)
			}
		}
	}
}

internal extension Home.VisitHub.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case visitHubButtonTapped
	}
}

internal extension Home.VisitHub.Action {
	init(action: Home.VisitHub.View.ViewAction) {
		switch action {
		case .visitHubButtonTapped:
			self = .internal(.user(.visitHubButtonTapped))
		}
	}
}

extension Home.VisitHub.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(
			state _: Home.VisitHub.State
		) {
			// TODO: implement
		}
	}
}

private extension Home.VisitHub.View {
	var title: some View {
		Text(L10n.Home.VisitHub.title)
			.foregroundColor(.app.buttonTextDark)
			.multilineTextAlignment(.center)
			.padding()
	}

	func visitHubButton(_ action: @escaping () -> Void) -> some View {
		Button(
			action: action,
			label: {
				Text(L10n.Home.VisitHub.buttonTitle)
					.foregroundColor(.app.buttonTextBlack)
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.app.buttonBackgroundLight)
					.cornerRadius(6)
			}
		)
	}
}
