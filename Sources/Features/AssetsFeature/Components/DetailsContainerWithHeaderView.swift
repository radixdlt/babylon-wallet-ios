import FeaturePrelude
import SwiftUI

// MARK: - DetailsContainerWithHeaderViewState
struct DetailsContainerWithHeaderViewState: Equatable {
	let title: String
	let amount: String?
	let symbol: String?
}

extension DetailsContainerWithHeaderViewState {
	init(resource: AccountPortfolio.FungibleResource) {
		self.init(
			title: resource.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			amount: resource.amount.format(),
			symbol: resource.symbol
		)
	}
}

// MARK: - DetailsContainerWithHeaderView
struct DetailsContainerWithHeaderView<ThumbnailView: View, DetailsView: View>: View {
	let viewState: DetailsContainerWithHeaderViewState
	let closeButtonAction: () -> Void

	let thumbnailView: ThumbnailView
	let detailsView: DetailsView

	init(
		viewState: DetailsContainerWithHeaderViewState,
		closeButtonAction: @escaping () -> Void,
		@ViewBuilder thumbnailView: () -> ThumbnailView,
		@ViewBuilder detailsView: () -> DetailsView
	) {
		self.viewState = viewState
		self.closeButtonAction = closeButtonAction
		self.thumbnailView = thumbnailView()
		self.detailsView = detailsView()
	}

	var body: some View {
		DetailsContainer(title: viewState.title, closeButtonAction: closeButtonAction) {
			VStack(spacing: .medium3) {
				header(with: viewState)

				detailsView
					.padding(.bottom, .medium3)
			}
		}
	}

	@ViewBuilder
	private func header(
		with viewState: DetailsContainerWithHeaderViewState
	) -> some View {
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

// MARK: - DetailsContainer
struct DetailsContainer<Contents: View>: View {
	let title: String
	let closeButtonAction: () -> Void
	let contents: Contents

	init(
		title: String,
		closeButtonAction: @escaping () -> Void,
		@ViewBuilder contents: () -> Contents
	) {
		self.title = title
		self.closeButtonAction = closeButtonAction
		self.contents = contents()
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				contents
			}
			#if os(iOS)
			.navigationBarTitle(title)
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
}
