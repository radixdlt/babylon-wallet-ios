import ComposableArchitecture
import SwiftUI

// MARK: - DetailsContainerWithHeaderViewState
struct DetailsContainerWithHeaderViewState: Equatable {
	let title: Loadable<String?>
	let amount: ResourceAmount?
	let currencyWorth: AttributedString?
	let symbol: Loadable<String?>
}

extension DetailsContainerWithHeaderViewState {
	init(_ resourceWithAmount: OnLedgerEntitiesClient.ResourceWithVaultAmount) {
		self.init(
			title: .success(resourceWithAmount.resource.metadata.name),
			amount: resourceWithAmount.amount,
			currencyWorth: nil,
			symbol: .success(resourceWithAmount.resource.metadata.symbol)
		)
	}
}

// MARK: - DetailsContainerWithHeaderView
struct DetailsContainerWithHeaderView<ThumbnailView: View, DetailsView: View>: View {
	@Environment(\.resourceBalanceHideFiatValue) var resourceBalanceHideFiatValue
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
				ResourceBalanceView.AmountView(
					amount: .init(amount),
					appearance: .large,
					symbol: viewState.symbol
				)
			}
		}
		.padding(.vertical, .small1)
	}
}

// MARK: - DetailsContainer
struct DetailsContainer<Contents: View>: View {
	let title: Loadable<String?>
	let closeButtonAction: () -> Void
	let contents: Contents

	init(
		title: Loadable<String?>,
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
			.radixToolbar(title: titleString)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					CloseButton(action: closeButtonAction)
				}
			}
		}
		.tint(.app.gray1)
		.foregroundColor(.app.gray1)
	}

	private var titleString: String {
		title.wrappedValue?.flatMap { $0 } ?? ""
	}
}
