import FeaturePrelude

// MARK: - PoolUnit.View
extension PoolUnit {
	public struct ViewState: Equatable {
		let iconURL: URL?
		let name: String
		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnit>

		public init(store: StoreOf<PoolUnit>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnit.Action.view
			) { viewStore in
				VStack(spacing: .medium3 * 2) {
					makePoolUnitView(
						viewState: .init(
							iconURL: viewStore.iconURL,
							name: viewStore.name
						)
					)
					.padding(.medium3 * -0.25)

					VStack(spacing: 1) {
						ForEach(
							viewStore.resources,
							content: makePoolUnitPoolUnitResourceView
						)
						.padding(.medium3)
						.background(.app.white)
					}
					.background(.app.gray4)
					.overlay(
						RoundedRectangle(cornerRadius: .small1)
							.stroke(.app.gray4, lineWidth: 1)
					)
					.padding(.small2 * -1)
				}
				.padding(.medium1)
				.background(.app.white)
				.roundedCorners(radius: .small1)
				.tokenRowShadow()
			}
		}
	}
}

extension PoolUnit.State {
	var viewState: PoolUnit.ViewState {
		let allResources = [poolUnit.poolResources.xrdResource!] + poolUnit.poolResources.nonXrdResources

		return .init(
			iconURL: poolUnit.pool.iconURL,
			name: poolUnit.pool.name ?? "Unknown",
			resources: .init(rawValue: .init(uniqueElements: allResources.map {
				PoolUnitResourceViewState(thumbnail: .known($0.iconURL), symbol: $0.symbol!, tokenAmount: $0.amount.format())
			}))!
		)
	}
}
