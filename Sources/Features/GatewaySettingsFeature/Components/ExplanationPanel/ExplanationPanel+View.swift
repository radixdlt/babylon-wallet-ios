import FeaturePrelude

extension ExplanationPanel.State {
	var viewState: ExplanationPanel.ViewState {
		.init(
			title: title,
			explanation: explanation
		)
	}
}

// MARK: - ExplanationPanel.View
extension ExplanationPanel {
	public struct ViewState: Equatable {
		let title: String
		let explanation: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ExplanationPanel>

		public init(store: StoreOf<ExplanationPanel>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					topBar(with: viewStore)

					ScrollView {
						VStack(spacing: .large3) {
							Text(viewStore.title)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)

							Text(viewStore.explanation)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.leading)

							Spacer()
						}
						.padding(.medium3)
					}
				}
				#if os(iOS)
				.onWillDisappear {
					viewStore.send(.willDisappear)
				}
				#endif
			}
		}

		private func topBar(with viewStore: ViewStoreOf<ExplanationPanel>) -> some SwiftUI.View {
			HStack {
				CloseButton { viewStore.send(.closeButtonTapped) }
				Spacer()
			}
			.padding(.small2)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ExplanationPanel_Preview
struct ExplanationPanel_Preview: PreviewProvider {
	static var previews: some View {
		ExplanationPanel.View(
			store: .init(
				initialState: .previewValue,
				reducer: ExplanationPanel()
			)
		)
	}
}

extension ExplanationPanel.State {
	public static let previewValue = Self(
		title: "A title",
		explanation: "Explanation text that can span across multiple lines and can probably be very long"
	)
}
#endif
