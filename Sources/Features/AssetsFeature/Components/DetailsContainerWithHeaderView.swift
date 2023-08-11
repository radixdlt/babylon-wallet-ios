import FeaturePrelude
import SwiftUI

// MARK: - DetailsContainerWithHeaderViewState
struct DetailsContainerWithHeaderViewState: Equatable {
	struct SymbolAndAmount: Equatable {
		let amount: String
		let symbol: String
	}

	let title: String
	let symbolAndAmount: SymbolAndAmount?
}

// MARK: - DetailsContainerWithHeaderView
struct DetailsContainerWithHeaderView<ThumbnailView, DetailsView>: View
	where ThumbnailView: View, DetailsView: View
{
	let viewState: DetailsContainerWithHeaderViewState
	let closeButtonAction: () -> Void

	let thumbnailView: ThumbnailView
	let detailsView: DetailsView

	init(
		viewState: DetailsContainerWithHeaderViewState,
		@ViewBuilder thumbnailView: () -> ThumbnailView,
		@ViewBuilder detailsView: () -> DetailsView,
		closeButtonAction: @escaping () -> Void
	) {
		self.viewState = viewState
		self.thumbnailView = thumbnailView()
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
						.padding(.vertical, .medium3)
				}
				.padding(.horizontal, .large2)
			}
			#if os(iOS)
			.navigationBarTitle(viewState.title)
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
	private func header(
		with viewState: DetailsContainerWithHeaderViewState
	) -> some SwiftUI.View {
		VStack(spacing: .medium3) {
			thumbnailView

			if let symbolAndAmount = viewState.symbolAndAmount {
				Text(symbolAndAmount.amount)
					.font(.app.sheetTitle)
					.kerning(-0.5)
					+ Text(" " + symbolAndAmount.symbol)
					.font(.app.sectionHeader)
			}
		}
		.padding(.vertical, .small2)
	}
}

// MARK: - DetailsContainerWithHeaderViewMaker
enum DetailsContainerWithHeaderViewMaker {
	static func makeSeparator() -> some View {
		Separator().padding(.horizontal, -.small2)
	}

	@ViewBuilder
	static func makeDescriptionView(description: String) -> some View {
		Text(description)
			.textStyle(.body1Regular)
			.frame(maxWidth: .infinity, alignment: .leading)

		DetailsContainerWithHeaderViewMaker.makeSeparator()
	}
}
