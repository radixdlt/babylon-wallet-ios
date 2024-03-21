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
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistory>

		public init(store: StoreOf<TransactionHistory>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
					let selection = viewStore.binding(get: \.currentMonth, send: ViewAction.selectedMonth)

					VStack(spacing: .zero) {
						VStack(spacing: .zero) {
							AccountHeaderView(account: viewStore.account)

							HScrollBar(items: viewStore.availableMonths, selection: selection)
								.background(.app.white)
								.padding(.vertical, .small2)

							if let filters = viewStore.activeFilters.nilIfEmpty {
								ActiveFiltersView(filters: filters) { id in
									store.send(.view(.filterCrossTapped(id)), animation: .default)
								}
								.padding(.bottom, .small1)
							}
						}
						.background(.app.white)

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
					.background(.app.gray5)
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
				.navigationTitle(L10n.TransactionHistory.title)
				.navigationBarTitleDisplayMode(.inline)
			}
			.onAppear {
				store.send(.view(.onAppear))
			}
			.destinations(with: store)
			.showDeveloperDisclaimerBanner(store.bannerStore)
		}

		private static let coordSpace = "TransactionHistory"
	}

	struct AccountHeaderView: SwiftUI.View {
		let account: Profile.Network.Account

		var body: some SwiftUI.View {
			SmallAccountCard(account: account)
				.roundedCorners(radius: .small1)
				.padding(.horizontal, .medium3)
				.padding(.top, .medium3)
				.background(.app.white)
		}
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

extension TransactionHistoryItem {
	var isEmpty: Bool {
		manifestClass != .accountDepositSettingsUpdate && deposits.isEmpty && withdrawals.isEmpty
	}
}

// MARK: - DateRangeItem
public struct DateRangeItem: ScrollBarItem, Sendable, Hashable, Identifiable {
	public var id: Date { startDate }
	public let caption: String
	let startDate: Date
	let endDate: Date
	var range: Range<Date> { startDate ..< endDate }
}

extension TransactionHistory.TransactionSection {
	var title: String {
		Self.string(from: day)
	}

	private static func string(from date: Date) -> String {
		let calendar: Calendar = .current

		if calendar.areSameYear(date, .now) {
			let dateString = sameYearFormatter.string(from: date)
			if calendar.isDateInToday(date) {
				return "\(L10n.TransactionHistory.DatePrefix.today), \(dateString)"
			} else if calendar.isDateInYesterday(date) {
				return "\(L10n.TransactionHistory.DatePrefix.yesterday), \(dateString)"
			} else {
				return dateString
			}
		} else {
			return otherYearFormatter.string(from: date)
		}
	}

	private static let sameYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = .localizedStringWithFormat("MMMM d")

		return formatter
	}()

	private static let otherYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = .localizedStringWithFormat("MMMM d, yyyy")
		return formatter
	}()
}

extension TransactionHistory {
	static func label(for transactionType: TransactionFilter.TransactionType?) -> String {
		switch transactionType {
		case let .some(transactionType): label(for: transactionType)
		case .none: L10n.TransactionHistory.ManifestClass.other
		}
	}

	static func label(for transactionType: TransactionFilter.TransactionType) -> String {
		switch transactionType {
		case .general: L10n.TransactionHistory.ManifestClass.general
		case .transfer: L10n.TransactionHistory.ManifestClass.transfer
		case .poolContribution: L10n.TransactionHistory.ManifestClass.contribute
		case .poolRedemption: L10n.TransactionHistory.ManifestClass.redeem
		case .validatorStake: L10n.TransactionHistory.ManifestClass.staking
		case .validatorUnstake: L10n.TransactionHistory.ManifestClass.unstaking
		case .validatorClaim: L10n.TransactionHistory.ManifestClass.claim
		case .accountDepositSettingsUpdate: L10n.TransactionHistory.ManifestClass.accountSettings
		}
	}
}
