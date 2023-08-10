import FeaturePrelude

extension PoolUnitsList.LSUResource {
	public struct ViewState: Sendable, Equatable {
		let isExpanded: Bool
		let iconURL: URL?
		let components: NonEmpty<IdentifiedArrayOf<LSUComponentView.ViewState>>
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList.LSUResource>

		@SwiftUI.State
		private var headerHeight: CGFloat = .zero

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

					cardBehindHeader(
						isStackExpanded: viewStore.isExpanded,
						headerHeight: headerHeight
					)
				}
			}
			.onPreferenceChange(HeightPreferenceKey.self) {
				headerHeight = $0
			}
		}

		private func headerView(
			with viewStore: ViewStore<ViewState, ViewAction>
		) -> some SwiftUI.View {
			PoolUnitHeaderView(viewState: .init(iconURL: viewStore.iconURL)) {
				VStack(alignment: .leading) {
					Text(L10n.Account.PoolUnits.lsuResourceHeader)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)

					Text(L10n.Account.PoolUnits.numberOfStakes(viewStore.components.count))
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}
			}
			.padding(.medium2)
			.background(.app.white)
			.roundedCorners(viewStore.isExpanded ? .top : .allCorners, radius: .small1)
			.tokenRowShadow(!viewStore.isExpanded)
			.zIndex(.infinity)
			.overlay(
				GeometryReader { geometry in
					Color.clear.anchorPreference(
						key: HeightPreferenceKey.self,
						value: .bounds
					) {
						geometry[$0].height
					}
				}
			)
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

		private func cardBehindHeader(
			isStackExpanded: Bool,
			headerHeight: CGFloat
		) -> some SwiftUI.View {
			GeometryReader { geometry in
				Spacer(
					minLength: isStackExpanded
						? .zero
						: headerHeight
				)
				.background(.app.white)
				.roundedCorners(
					.bottom,
					radius: .small1
				)
				.frame(width: geometry.size.width)
				.scaleEffect(0.95)
				.tokenRowShadow(!isStackExpanded)
				.opacity(isStackExpanded ? 0 : 1)
				.offset(y: .small1)
			}
		}
	}
}

// MARK: - HeightPreferenceKey
private struct HeightPreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = .zero

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

extension PoolUnitsList.LSUResource.State {
	var viewState: PoolUnitsList.LSUResource.ViewState {
		.init(
			isExpanded: isExpanded,
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			components: .init(
				rawValue: .init(
					uncheckedUniqueElements: stakes
						.map { stake in
							LSUComponentView.ViewState(
								id: stake.validator.address,
								title: stake.validator.name ?? L10n.Account.PoolUnits.unknownValidatorName,
								imageURL: stake.validator.iconURL,
								liquidStakeUnit: stake.xrdRedemptionValue
									.map {
										.init(
											thumbnail: .xrd,
											symbol: "XRD",
											tokenAmount: $0.format()
										)
									},
								stakeClaimNFTs: .init(
									rawValue: stake.stakeClaimResource
										.map { claimNFT in
											.init(
												uncheckedUniqueElements: claimNFT.tokens
													.map { token in
														LSUComponentView.StakeClaimNFTViewState(
															id: token.id,
															thumbnail: .xrd,
															status: token.canBeClaimed ? .readyToClaim : .unstaking,
															tokenAmount: (token.stakeClaimAmount ?? 0).format()
														)
													}
											)
										} ?? []
								)
							)
						}
				)
			)!
		)
	}
}
