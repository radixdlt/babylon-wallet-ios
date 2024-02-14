// MARK: - PoolUnitView
public struct PoolUnitView: View {
	public struct ViewState: Equatable {
		public let poolName: String?
		public let amount: RETDecimal?
		public let guaranteedAmount: RETDecimal?
		public let dAppName: Loadable<String?>
		public let poolIcon: URL?
//		public let resources: Loadable<[PoolUnitResourceView.ViewState]>
		public let resources: Loadable<[ResourcesListView.ResourceViewState]>
		public let isSelected: Bool?
	}

	public let viewState: ViewState
	public let background: Color
	public let onTap: () -> Void

	public var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .zero) {
					Thumbnail(.poolUnit, url: viewState.poolIcon, size: .extraSmall)
						.padding(.trailing, .small1)

					VStack(alignment: .leading, spacing: 0) {
						Text(viewState.poolName ?? L10n.TransactionReview.poolUnits)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						loadable(viewState.dAppName, loadingViewHeight: .small1) { dAppName in
							if let dAppName {
								Text(dAppName)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
							}
						}
					}

					Spacer(minLength: 0)

					if let amount = viewState.amount {
						TransactionReviewAmountView(amount: amount, guaranteedAmount: viewState.guaranteedAmount)
							.padding(.leading, viewState.isSelected != nil ? .small2 : 0)
					}

					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}

					//					AssetIcon(.asset(AssetResource.info), size: .smallest)
					//						.tint(.app.gray3)
				}
				.padding(.bottom, .small2)

				Text(L10n.TransactionReview.worth.uppercased())
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.padding(.bottom, .small3)

//				loadable(viewState.resources) { resources in
//					PoolUnitResourcesView(resources: resources)
//				}

				loadable(viewState.resources) { resources in
					ResourcesListView(resources: resources)
				}
			}
			.padding(.medium3)
			.background(background)
		}
		.buttonStyle(.borderless)
	}
}

// MARK: - PoolUnitResourcesView
public struct PoolUnitResourcesView: View {
	public let resources: [PoolUnitResourceView.ViewState]

	public var body: some View {
		VStack(spacing: 0) {
			ForEach(resources) { resource in
				let isNotLast = resource.id != resources.last?.id
				PoolUnitResourceView(viewState: resource)
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

// MARK: - PoolUnitResourceView
public struct PoolUnitResourceView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress
		public let symbol: String?
		public let icon: Thumbnail.FungibleContent
		public let amount: String

		public init(
			id: ResourceAddress,
			symbol: String?,
			icon: Thumbnail.FungibleContent,
			amount: RETDecimal?
		) {
			self.id = id
			self.symbol = symbol
			self.icon = icon
			self.amount = amount.map { $0.formatted() } ?? L10n.Account.PoolUnits.noTotalSupply
		}
	}

	public let viewState: ViewState

	public var body: some View {
		HStack(spacing: .zero) {
			Thumbnail(fungible: viewState.icon, size: .smallest)
				.padding(.trailing, .small1)

			if let symbol = viewState.symbol {
				Text(symbol)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: .small2)

			Text(viewState.amount)
				.lineLimit(1)
				.minimumScaleFactor(0.8)
				.truncationMode(.tail)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)
		}
	}
}

// MARK: - ResourcesListView
public struct ResourcesListView: View {
	public enum ResourceViewState: Identifiable, Equatable {
		case fungible(CompactFungibleView.ViewState)
		//		case nonFungible(SmallNonfungibleResourceView.ViewState)

		public var id: ResourceAddress {
			switch self {
			case let .fungible(fungible):
				fungible.id
			}
		}
	}

	public let resources: [ResourceViewState]

	public var body: some View {
		VStack(spacing: 0) {
			ForEach(resources) { resource in
				let isNotLast = resource.id != resources.last?.id
				resourceView(resource)
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

	private func resourceView(_ resource: ResourceViewState) -> some View {
		switch resource {
		case let .fungible(fungible):
			CompactFungibleView(viewState: fungible)
		}
	}

	private let dividerHeight: CGFloat = 1
}

// MARK: - CompactFungibleView
public struct CompactFungibleView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress { address }

		public let address: ResourceAddress
		public let symbol: String?
		public let icon: Thumbnail.FungibleContent
		public let amount: RETDecimal?
		public let fallback: String?

		var amountString: String? {
			amount.map { $0.formatted() } ?? fallback
		}
	}

	public let viewState: ViewState

	public var body: some View {
		HStack(spacing: .zero) {
			Thumbnail(fungible: viewState.icon, size: .smallest)
				.padding(.trailing, .small1)

			if let symbol = viewState.symbol {
				Text(symbol)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: .small2)

			if let amountString = viewState.amountString {
				Text(amountString)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.truncationMode(.tail)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
			}
		}
	}
}
