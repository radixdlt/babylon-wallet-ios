import FeaturePrelude

extension Header.State {
	var viewState: Header.ViewState {
		.init()
	}
}

extension Header {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Header>

		init(store: StoreOf<Header>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack(alignment: .leading, spacing: .small2) {
					Text(L10n.HomePage.title)
						.foregroundColor(.app.gray1)
						.textStyle(.sheetTitle)

					HStack {
						Text(L10n.HomePage.subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.lineLimit(2)

						Spacer(minLength: 2 * .large1)
					}
				}
				.padding(.leading, .medium1)
				.padding(.top, .small3)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Header_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			ScrollView {
				Header.View(
					store: .init(
						initialState: .previewValue,
						reducer: Header.init
					)
				)
			}
		}
	}
}

extension Header.State {
	static let previewValue = Self()
}
#endif
