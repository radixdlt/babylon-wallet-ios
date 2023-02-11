import FeaturePrelude

// MARK: - Home.VisitHub.View
extension Home.VisitHub {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

extension Home.VisitHub.View {
	public var body: some View {
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
			.cornerRadius(.small2)
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

extension Home.VisitHub.View {
	fileprivate var title: some View {
		Text(L10n.Home.VisitHub.title)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.multilineTextAlignment(.center)
			.padding()
	}

	fileprivate func visitHubButton(_ action: @escaping () -> Void) -> some View {
		Button(
			action: action,
			label: {
				Text(L10n.Home.VisitHub.buttonTitle)
					.foregroundColor(.app.buttonTextBlack)
					.textStyle(.body1Regular)
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.app.gray4)
					.cornerRadius(.small2)
			}
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

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
#endif
