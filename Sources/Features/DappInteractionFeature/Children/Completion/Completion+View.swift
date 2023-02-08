import FeaturePrelude

// MARK: - Completion.View
extension Completion {
	struct ViewState: Equatable {
		let title: String
		let subtitle: String

		init(state: Completion.State) {
			title = L10n.DApp.Completion.title
			subtitle = L10n.DApp.Completion.subtitle(state.dappMetadata.name.rawValue)
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Completion>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: Completion.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				VStack(spacing: 0) {
					NavigationBar(
						leadingItem: CloseButton { viewStore.send(.closeButtonTapped) }
					)
					VStack(spacing: .medium2) {
						Image(asset: AssetResource.successCheckmark)

						Text(viewStore.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium1)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton { viewStore.send(.closeButtonTapped) }
							}
						}
					#endif
				}
				.padding([.top, .horizontal], .small2)
				.padding(.bottom, .medium3)
			}
			.presentationDragIndicator(.visible)
			.presentationDetentIntrinsicHeight()
			.presentationDetentBlurBackground()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Completion_Preview
struct Completion_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		WithState(initialValue: false) { $isPresented in
			ZStack {
				Color.red
				Button("Present") { isPresented = true }
			}
			.sheet(isPresented: $isPresented) {
				Completion.View(
					store: .init(
						initialState: .previewValue,
						reducer: Completion()
					)
				)
			}
			.task {
				try? await Task.sleep(for: .seconds(2))
				isPresented = true
			}
		}
	}
}

extension Completion.State {
	static let previewValue: Self = .init(dappMetadata: .previewValue)
}
#endif
