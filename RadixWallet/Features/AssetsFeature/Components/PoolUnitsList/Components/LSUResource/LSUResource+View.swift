import ComposableArchitecture
import SwiftUI

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
				Section {
					headerView(with: viewStore)
						.rowStyle()

					if viewStore.isExpanded {
						componentsView
					}
				}
			}
		}

		private func headerView(
			with viewStore: ViewStore<ViewState, ViewAction>
		) -> some SwiftUI.View {
			PoolUnitHeaderView(viewState: .init(iconURL: viewStore.iconURL)) {
				VStack(alignment: .leading, spacing: .small3) {
					Text("Radix Network XRD Stake") // This is temporary, stakes will be redesigned.
						.lineSpacing(-12)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)

					Text("\(viewStore.numberOfStakes) Stakes") // This is temporary, stakes will be redesigned.
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}
			}
			.padding(.medium2)
			.onTapGesture {
				viewStore.send(.isExpandedToggled, animation: .easeInOut)
			}
		}

		private var componentsView: some SwiftUI.View {
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
			.rowStyle()
		}
	}
}

extension LSUResource.State {
	var viewState: LSUResource.ViewState {
		.init(
			isExpanded: isExpanded,
			// TODO: Should use an Asset instead
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			numberOfStakes: account.poolUnitResources.radixNetworkStakes.count
		)
	}
}
