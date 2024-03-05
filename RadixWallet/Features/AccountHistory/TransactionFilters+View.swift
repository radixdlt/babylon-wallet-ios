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
			FlowLayout(spacing: .small1) {
				ForEach(filters) { filter in
					FilterView(filter: filter) {
						store.send(.view(.addTapped(filter.id)))
					} removeAction: {
						store.send(.view(.removeTapped(filter.id)))
					}
				}
			}
		}

		struct FilterView: SwiftUI.View {
			let filter: State.Filter
			let addAction: () -> Void
			let removeAction: () -> Void

			var body: some SwiftUI.View {
				Button(action: addAction) {
					// Animating the foreground color directly causes a glitch
					ZStack {
						Text(filter.label)
							.foregroundStyle(.app.white)
							.opacity(filter.isActive ? 1 : 0)
						Text(filter.label)
							.foregroundStyle(.app.gray1)
							.opacity(filter.isActive ? 0 : 1)
					}
					.textStyle(.body1HighImportance)
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small2)
				}
				.contentShape(Capsule())
				.disabled(filter.isActive)
				.padding(.trailing, filter.isActive ? .medium1 : 0)
				.background {
					ZStack {
						Capsule().fill(filter.isActive ? .app.gray1 : .app.white)
						Capsule().stroke(filter.isActive ? .clear : .app.gray3)
					}
				}
				.overlay(alignment: .trailing) {
					if filter.isActive {
						Button(asset: AssetResource.close, action: removeAction)
							.tint(.app.gray3)
							.padding(.vertical, -.small3)
							.padding(.trailing, .small2)
							.transition(.scale.combined(with: .opacity))
					}
				}
				.animation(.default.speed(2), value: filter.isActive)
			}

			struct Dummy: SwiftUI.View {
				var body: some SwiftUI.View {
					Text("ABC")
						.textStyle(.body1HighImportance)
						.padding(.vertical, .small2)
				}
			}
		}
	}
}
