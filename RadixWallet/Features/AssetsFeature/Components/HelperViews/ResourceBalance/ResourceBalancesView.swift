import SwiftUI

// MARK: - ResourceBalancesView
public struct ResourceBalancesView: View {
	public let viewState: [ResourceBalance.ViewState]

	public init(_ viewState: [ResourceBalance.ViewState]) {
		self.viewState = viewState
	}

	public init(fungibles: [ResourceBalance.ViewState.Fungible]) {
		self.init(fungibles.map(ResourceBalance.ViewState.fungible))
	}

	public init(nonFungibles: [ResourceBalance.ViewState.NonFungible]) {
		self.init(nonFungibles.map(ResourceBalance.ViewState.nonFungible))
	}

	public var body: some View {
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
