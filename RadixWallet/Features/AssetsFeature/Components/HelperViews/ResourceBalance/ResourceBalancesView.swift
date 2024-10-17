import SwiftUI

// MARK: - ResourceBalancesView
struct ResourceBalancesView: View {
	let viewState: [ResourceBalance.ViewState]

	init(_ viewState: [ResourceBalance.ViewState]) {
		self.viewState = viewState
	}

	init(fungibles: [ResourceBalance.ViewState.Fungible]) {
		self.init(fungibles.map(ResourceBalance.ViewState.fungible))
	}

	init(nonFungibles: [ResourceBalance.ViewState.NonFungible]) {
		self.init(nonFungibles.map(ResourceBalance.ViewState.nonFungible))
	}

	var body: some View {
		VStack(spacing: 0) {
			ForEach(viewState) { resource in
				let isNotLast = resource.id != viewState.last?.id
				ResourceBalanceView(resource, appearance: .compact)
					.padding(.small1)
					.padding(.bottom, isNotLast ? dividerHeight : 0)
					.overlay(alignment: .bottom) {
						if isNotLast {
							Rectangle()
								.fill(.app.gray3)
								.frame(height: dividerHeight)
						}
					}
			}
		}
		.roundedCorners(strokeColor: .app.gray3)
	}

	private let dividerHeight: CGFloat = 1
}
