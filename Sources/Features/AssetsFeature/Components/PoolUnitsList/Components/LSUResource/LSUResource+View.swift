import FeaturePrelude

extension PoolUnitsList.LSUResource.State {
	var viewState: PoolUnitsList.LSUResource.ViewState {
		.init(
			isExpanded: isExpanded,
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			name: "Radix Network XRD Stake",
			components: .init(
				[
					.init(
						title: "Radostakes",
						liquidStakeUnit: .init(
							thumbnail: .xrd,
							symbol: "XRD",
							tokenAmount: "2.0129822"
						),
						stakeClaimNFTs: .init(
							rawValue: [
								.init(
									id: 0,
									thumbnail: .xrd,
									status: .unstaking,
									tokenAmount: "450.0"
								),
								.init(
									id: 1,
									thumbnail: .xrd,
									status: .unstaking,
									tokenAmount: "1,250.0"
								),
								.init(
									id: 2,
									thumbnail: .xrd,
									status: .readyToClaim,
									tokenAmount: "1,200.0"
								),
							]
						)
					),
					.init(
						title: "Radix N Stakes",
						liquidStakeUnit: nil,
						stakeClaimNFTs: .init(
							rawValue: [
								.init(
									id: 0,
									thumbnail: .xrd,
									status: .unstaking,
									tokenAmount: "23,2132.321"
								),
							]
						)
					),
				]
			)!
		)
	}
}

extension PoolUnitsList.LSUResource {
	public struct ViewState: Sendable, Equatable {
		let isExpanded: Bool
		let iconURL: URL
		let name: String
		let components: NonEmpty<IdentifiedArrayOf<LSUComponentView.ViewState>>
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList.LSUResource>

		public init(store: StoreOf<PoolUnitsList.LSUResource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitsList.LSUResource.Action.view
			) { viewStore in
				StackedViewsLayout(
					isExpanded: viewStore.isExpanded,
					spacing: 1,
					collapsedViewsCount: 1
				) {
					headerView(with: viewStore)

					if viewStore.isExpanded {
						componentsView(with: viewStore.components.rawValue)
					}

					GeometryReader { geometry in
						Spacer(
							minLength: viewStore.isExpanded
								? .zero
								: 88
						)
						.padding(
							viewStore.isExpanded
								? .zero
								: .medium1
						)
						.background(.app.white)
						.roundedCorners(
							.bottom,
							radius: .small1
						)
						.frame(width: geometry.size.width)
						.scaleEffect(0.95)
						.tokenRowShadow(!viewStore.isExpanded)
						.opacity(viewStore.isExpanded ? 0 : 1)
					}
				}
				.padding(.medium1)
			}
		}

		private func headerView(
			with viewStore: ViewStore<ViewState, ViewAction>
		) -> some SwiftUI.View {
			HStack(spacing: .medium2) {
				NFTThumbnail(viewStore.iconURL, size: .small)

				VStack(alignment: .leading) {
					Text(viewStore.name)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)

					Text("3 Stakes")
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}

				Spacer()
			}
			.padding(.medium1)
			.background(.app.white)
			.roundedCorners(viewStore.isExpanded ? .top : .allCorners, radius: .small1)
			.zIndex(.infinity)
			.roundedCorners(
				viewStore.isExpanded
					? .top
					: .allCorners,
				radius: .small1
			)
			.tokenRowShadow(!viewStore.isExpanded)
			.onTapGesture {
				viewStore.send(.isExpandedToggled, animation: .easeInOut)
			}
		}

		private func componentsView(
			with componentViewStates: IdentifiedArrayOf<LSUComponentView.ViewState>
		) -> some SwiftUI.View {
			VStack(spacing: 1) {
				ForEach(componentViewStates, content: LSUComponentView.init)
					.background(.app.white)
			}
			.roundedCorners(
				.bottom,
				radius: .small1
			)
		}
	}
}
