import FeaturePrelude
import SwiftUI

// MARK: - DetailsContainerWithHeaderViewState
struct DetailsContainerWithHeaderViewState: Equatable {
	let title: String
	let amount: String?
	let symbol: String?
}

// MARK: - DetailsContainerWithHeaderView
struct DetailsContainerWithHeaderView<ThumbnailView: View, DetailsView: View>: View {
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
				VStack(spacing: .medium3) {
					header(with: viewState)

					detailsView
						.padding(.bottom, .medium3)
				}
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

			if let amount = viewState.amount {
				Text(amount)
					.font(.app.sheetTitle)
					.kerning(-0.5)
					+ Text((viewState.symbol).map { " " + $0 } ?? "")
					.font(.app.sectionHeader)
			}
		}
		.padding(.vertical, .small2)
	}
}
