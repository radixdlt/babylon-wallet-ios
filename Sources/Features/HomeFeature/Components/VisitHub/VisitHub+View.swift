import Common
import ComposableArchitecture
import SwiftUI

// MARK: - Home.VisitHub.View
public extension Home.VisitHub {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

public extension Home.VisitHub.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack {
				title
				visitHubButton {
					viewStore.send(.visitHubButtonTapped)
				}
			}
			.background(Color.app.gray3)
			.cornerRadius(6)
		}
	}
}

// MARK: - Home.VisitHub.View.ViewState
extension Home.VisitHub.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.VisitHub.State) {}
	}
}

private extension Home.VisitHub.View {
	var title: some View {
		Text(L10n.Home.VisitHub.title)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.multilineTextAlignment(.center)
			.padding()
	}

	func visitHubButton(_ action: @escaping () -> Void) -> some View {
		Button(
			action: action,
			label: {
				Text(L10n.Home.VisitHub.buttonTitle)
					.foregroundColor(.app.buttonTextBlack)
					.textStyle(.body1Regular)
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.app.gray4)
					.cornerRadius(6)
			}
		)
	}
}

// MARK: - VisitHub_Preview
struct VisitHub_Preview: PreviewProvider {
	static var previews: some View {
		Home.VisitHub.View(
			store: .init(
				initialState: .init(),
				reducer: Home.VisitHub()
			)
		)
	}
}
