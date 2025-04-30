import ComposableArchitecture
import SwiftUI

extension TransactionHistory.State {
	var showEmptyState: Bool {
		sections.isEmpty && !loading.isLoading
	}
}

// MARK: - TransactionHistory.View
extension TransactionHistory {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistory>

		init(store: StoreOf<TransactionHistory>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
					let selection = viewStore.binding(get: \.currentMonth, send: ViewAction.selectedMonth)

					VStack(spacing: .zero) {
						VStack(spacing: .small2) {
							AccountCard(account: viewStore.account)
								.padding(.horizontal, .medium3)

							if let filters = viewStore.activeFilters.nilIfEmpty {
								ActiveFiltersView(filters: filters) { id in
									store.send(.view(.filterCrossTapped(id)), animation: .default)
								}
							}

							HScrollBar(items: viewStore.availableMonths, selection: selection)
								.background(.primaryBackground)
						}
						.padding(.top, .small3)
						.padding(.bottom, .small1)
						.background(.primaryBackground)

						TableView(
							sections: viewStore.sections,
							scrollTarget: viewStore.scrollTarget
						) { action in
							store.send(.view(.transactionsTableAction(action)))
						}
						.ignoresSafeArea(edges: .bottom)
						.opacity(viewStore.sections == [] ? 0 : 1)
						.background(alignment: .top) {
							if viewStore.loading.isLoading {
								ProgressView()
									.padding(.small3)
							}
						}
					}
					.background {
						if viewStore.showEmptyState {
							Text(L10n.TransactionHistory.noTransactions)
								.textStyle(.sectionHeader)
								.foregroundStyle(.app.gray2)
						}
					}
					.background(.secondaryBackground)
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							CloseButton {
								store.send(.view(.closeTapped))
							}
						}
						ToolbarItem(placement: .topBarTrailing) {
							Button(asset: AssetResource.transactionHistoryFilterList) {
								store.send(.view(.filtersTapped))
							}
						}
					}
				}
				.radixToolbar(title: L10n.TransactionHistory.title, alwaysVisible: false)
			}
			.onAppear {
				store.send(.view(.onAppear))
			}
			.destinations(with: store)
			.showDeveloperDisclaimerBanner(store.bannerStore)
		}

		private static let coordSpace = "TransactionHistory"
	}

	struct ActiveFiltersView: SwiftUI.View {
		let filters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter>
		let crossAction: (TransactionFilter) -> Void

		var body: some SwiftUI.View {
			ScrollView(.horizontal) {
				HStack {
					ForEach(filters) { filter in
						TransactionFilterView(filter: filter, action: { _ in }, crossAction: crossAction)
					}

					Spacer(minLength: 0)
				}
				.padding(.horizontal, .medium3)
			}
		}
	}
}

private extension StoreOf<TransactionHistory> {
	var destination: PresentationStoreOf<TransactionHistory.Destination> {
		func scopeState(state: State) -> PresentationState<TransactionHistory.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<TransactionHistory>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.filters, action: \.filters)) {
			TransactionHistoryFilters.View(store: $0)
		}
	}
}

// MARK: - DateRangeItem
struct DateRangeItem: ScrollBarItem, Sendable, Hashable, Identifiable {
	var id: Date { startDate }
	let caption: String
	let startDate: Date
	let endDate: Date
	var range: Range<Date> { startDate ..< endDate }
}
