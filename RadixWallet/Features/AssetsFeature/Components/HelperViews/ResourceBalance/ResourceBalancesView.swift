import SwiftUI

// MARK: - ResourceBalancesView
struct ResourceBalancesView: View {
	let viewState: [ResourceBalance.ViewState]
	let appearance: ResourceBalanceView.Appearance

	init(
		_ viewState: [ResourceBalance.ViewState],
		appearance: ResourceBalanceView.Appearance
	) {
		self.viewState = viewState
		self.appearance = appearance
	}

	init(
		fungibles: [ResourceBalance.ViewState.Fungible],
		appearance: ResourceBalanceView.Appearance
	) {
		self.init(fungibles.map(ResourceBalance.ViewState.fungible), appearance: appearance)
	}

	init(
		nonFungibles: [ResourceBalance.ViewState.NonFungible],
		appearance: ResourceBalanceView.Appearance
	) {
		self.init(nonFungibles.map(ResourceBalance.ViewState.nonFungible), appearance: appearance)
	}

	var body: some View {
		VStack(spacing: 0) {
			ForEach(viewState) { resource in
				let isNotLast = resource.id != viewState.last?.id
				ResourceBalanceView(resource, appearance: appearance)
					.padding(.small1)
					.padding(.bottom, isNotLast ? dividerHeight : 0)
					.overlay(alignment: .bottom) {
						if isNotLast {
							Separator()
						}
					}
			}
		}
		.roundedCorners(strokeColor: .border)
	}

	private let dividerHeight: CGFloat = 1
}
