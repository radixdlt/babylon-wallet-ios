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
				VStack(spacing: 20) {
					Text(L10n.Home.VisitHub.title)
						.multilineTextAlignment(.center)

					Button(action: { viewStore.send(.visitHubButtonTapped) },
					       label: {
					       	Text(L10n.Home.VisitHub.buttonTitle)
					       		.frame(maxWidth: .infinity)
					       		.background(Color.red)
					       })
				}
				.background(Color.green)
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
		init(state _: Home.VisitHub.State) {
			// TODO: implement
		}
	}
}

private extension Home.VisitHub.View {
	// TODO: extract subviews
}
