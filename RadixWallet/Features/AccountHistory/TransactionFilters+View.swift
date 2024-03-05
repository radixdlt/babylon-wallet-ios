import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistoryFilters.View
extension TransactionFilters {
	public typealias ViewState = State.Filters

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionFilters>

		public init(store: StoreOf<TransactionFilters>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.filters, send: { .view($0) }) { viewStore in
				VStack {
					section(filters: viewStore.transferTypes)

					Text("Type of asset")

					Text("Tokens")
					section(filters: viewStore.fungibles)

					Text("NFTs")
					section(filters: viewStore.nonFungibles)

					Text("Type of transaction")
					section(filters: viewStore.transactionTypes)
				}
			}
		}

		private func section(filters: IdentifiedArrayOf<State.Filter>) -> some SwiftUI.View {
			ForEach(filters) { filter in
				HStack {
					FilterView(filter: filter) {
						store.send(.view(filter.isActive ? .removeTapped(filter.id) : .addTapped(filter.id)))
					}
				}
			}
		}

		struct FilterView: SwiftUI.View {
			let filter: State.Filter
			let action: () -> Void

			var body: some SwiftUI.View {
				if filter.isActive {
					core
				} else {
					Button(action: action) {
						core
					}
					.contentShape(Capsule())
				}
			}

			private var core: some SwiftUI.View {
				HStack(spacing: .small2) {
					Text(filter.label)
						.textStyle(.body1HighImportance)
						.foregroundStyle(filter.isActive ? .app.white : .app.gray1)

					if filter.isActive {
						Button(asset: AssetResource.close, action: action)
							.tint(.app.gray3)
							.padding(-.small3)
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small2)
				.background(background)
			}

			@ViewBuilder
			private var background: some SwiftUI.View {
				if filter.isActive {
					Capsule().fill(.app.gray1)
				} else {
					Capsule().stroke(.app.gray3)
				}
			}
		}
	}
}
