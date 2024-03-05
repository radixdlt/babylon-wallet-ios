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
					FilterSection(filters: viewStore.transferTypes)

					Text("Type of asset")

					Text("Tokens")
					FilterSection(filters: viewStore.fungibles)

					Text("NFTs")
					FilterSection(filters: viewStore.nonFungibles)

					Text("Type of transaction")
					FilterSection(filters: viewStore.transactionTypes)
				}
			}
		}

		struct FilterSection: SwiftUI.View {
			let filters: IdentifiedArrayOf<State.Filter>

			var body: some SwiftUI.View {
				ForEach(filters) { filter in
					HStack {
						FilterView(filter: filter) {
							print("FILTER \(filter.label)")
						}
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
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.trailing, filter.isActive ? -.small3 : 0) // Adjust for spacing inside "X"
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
