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
				VStack(spacing: .large2) {
					PoolUnitHeaderView(viewState: .init(iconURL: viewStore.iconURL)) {
						Text(viewStore.name)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
					}
					.padding(.small3 * -1)

					VStack(spacing: 1) {
						ForEach(
							viewStore.resources,
							content: poolUnitResourceView
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

		private func poolUnitResourceView(
			viewState: PoolUnitResourceViewState
		) -> some SwiftUI.View {
			PoolUnitResourceView(viewState: viewState) {
				Text(viewState.symbol)
					.foregroundColor(.app.gray1)
					.textStyle(.body2HighImportance)
			}
		}
	}
}

extension PoolUnit.State {
	// FIXME: Rewire to real State
	var viewState: PoolUnit.ViewState {
		let xrdResourceViewState = poolUnit.poolResources.xrdResource.map {
			[PoolUnitResourceViewState(
				thumbnail: .xrd,
				symbol: "XRD",
				tokenAmount: poolUnit.redemptionValue(for: $0).format()
			)]
		} ?? []

		let allResourceViewStates = xrdResourceViewState + poolUnit.poolResources.nonXrdResources.map {
			PoolUnitResourceViewState(
				thumbnail: .known($0.iconURL),
				symbol: $0.symbol ?? $0.name ?? "Unknown",
				tokenAmount: poolUnit.redemptionValue(for: $0).format()
			)
		}

		return .init(
			iconURL: poolUnit.poolUnitResource.iconURL,
			name: poolUnit.poolUnitResource.name ?? "Unknown",
			resources: .init(rawValue: .init(uniqueElements: allResourceViewStates))! // Safe to unwrap, guaranteed to not be empty
		)
	}
}
