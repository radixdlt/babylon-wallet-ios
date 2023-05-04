import FeaturePrelude

extension VisitHub.State {
	var viewState: VisitHub.ViewState {
		.init()
	}
}

extension VisitHub {
	struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<State, Action>

		init(store: Store<State, Action>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
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

		fileprivate var title: some SwiftUI.View {
			Text(L10n.Home.VisitDashboard.subtitle)
				.foregroundColor(.app.gray1)
				.textStyle(.body1Regular)
				.multilineTextAlignment(.center)
				.padding()
		}

		fileprivate func visitHubButton(_ action: @escaping () -> Void) -> some SwiftUI.View {
			Button(
				action: action,
				label: {
					Text(L10n.Home.visitDashboard)
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
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct VisitHub_Preview: PreviewProvider {
	static var previews: some View {
		VisitHub.View(
			store: .init(
				initialState: .previewValue,
				reducer: VisitHub()
			)
		)
	}
}

extension VisitHub.State {
	public static let previewValue = Self()
}
#endif
