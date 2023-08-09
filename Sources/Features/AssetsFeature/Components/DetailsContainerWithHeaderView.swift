import FeaturePrelude
import SwiftUI

// MARK: - DetailsContainerWithHeaderViewState
struct DetailsContainerWithHeaderViewState: Equatable {
	let displayName: String
	let thumbnail: TokenThumbnail.Content
	let amount: String
	let symbol: String?
}

// MARK: - DetailsContainerWithHeaderView
struct DetailsContainerWithHeaderView<DetailsView>: View where DetailsView: View {
	let viewState: DetailsContainerWithHeaderViewState
	let closeButtonAction: () -> Void
	let detailsView: DetailsView

	init(
		viewState: DetailsContainerWithHeaderViewState,
		@ViewBuilder detailsView: () -> DetailsView,
		closeButtonAction: @escaping () -> Void
	) {
		self.viewState = viewState
		self.detailsView = detailsView()
		self.closeButtonAction = closeButtonAction
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				Group {
					header(with: viewState)

					DetailsContainerWithHeaderViewMaker.makeSeparator()

					detailsView
				}
				.padding(.horizontal, .large2)
			}
			#if os(iOS)
			.navigationBarTitle(viewState.displayName)
			.navigationBarTitleColor(.app.gray1)
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarInlineTitleFont(.app.secondaryHeader)
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					CloseButton(action: closeButtonAction)
				}
			}
			#endif
		}
		.tint(.app.gray1)
		.foregroundColor(.app.gray1)
	}

	@ViewBuilder
	private func header(with viewState: DetailsContainerWithHeaderViewState) -> some SwiftUI.View {
		VStack(spacing: .medium3) {
			TokenThumbnail(viewState.thumbnail, size: .veryLarge)
			if let symbol = viewState.symbol {
				Text(viewState.amount)
					.font(.app.sheetTitle)
					.kerning(-0.5)
					+ Text(" " + symbol)
					.font(.app.sectionHeader)
			}
		}
		.padding(.top, .small2)
	}
}

// MARK: - DetailsContainerWithHeaderViewMaker
enum DetailsContainerWithHeaderViewMaker {
	static func makeSeparator() -> some View {
		Separator().padding(.horizontal, -.small2)
	}

	@ViewBuilder
	static func makeDescriptionView(description: String?) -> some View {
		if let description = description {
			Group {
				Text(description)
					.textStyle(.body1Regular)
					.frame(maxWidth: .infinity, alignment: .leading)

				DetailsContainerWithHeaderViewMaker.makeSeparator()
			}
		} else {
			EmptyView()
		}
	}
}
