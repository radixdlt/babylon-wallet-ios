import FeaturePrelude

extension LSUResource {
	public struct ViewState: Sendable, Equatable {
		let isExpanded: Bool
		let iconURL: URL?
		let numberOfStakes: Int
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<LSUResource>

		@SwiftUI.State
		private var headerHeight: CGFloat = .zero

		public init(store: StoreOf<LSUResource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: LSUResource.Action.view
			) { viewStore in
				StackedViewsLayout(
					isExpanded: viewStore.isExpanded,
					spacing: 1,
					collapsedViewsCount: 1
				) {
					headerView(with: viewStore)

					if viewStore.isExpanded {
						componentsView
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

					Text(L10n.Account.PoolUnits.numberOfStakes(viewStore.numberOfStakes))
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

		private var componentsView: some SwiftUI.View {
			VStack(spacing: 1) {
				ForEachStore(
					store.scope(
						state: \.stakes,
						action: (
							/LSUResource.Action.child
								.. LSUResource.ChildAction.stake
						).embed
					),
					content: LSUStake.View.init
				)
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

extension LSUResource.State {
	var viewState: LSUResource.ViewState {
		.init(
			isExpanded: isExpanded,
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			numberOfStakes: stakes.count
		)
	}
}
