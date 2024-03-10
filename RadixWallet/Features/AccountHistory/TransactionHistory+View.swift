import ComposableArchitecture
import SwiftUI

extension TransactionHistory.State {
	var showEmptyState: Bool {
		sections.isEmpty && !isLoading
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
					let accountHeader = AccountHeaderView(account: viewStore.account)

					let selection = viewStore.binding(get: \.selectedPeriod, send: ViewAction.selectedPeriod)

					VStack(spacing: .zero) {
						VStack(spacing: .small2) {
							HScrollBarDummy()

							if !viewStore.activeFilters.isEmpty {
								ActiveFiltersView.Dummy()
							}
						}
						.padding(.top, .small2)
						.padding(.bottom, .small1)

						ScrollView {
							LazyVStack(spacing: .small1, pinnedViews: [.sectionHeaders]) {
								accountHeader
									.measurePosition(View.accountDummy, coordSpace: View.coordSpace)
									.opacity(0)

								ForEach(viewStore.sections) { section in
									SectionView(section: section)
								}
							}
							.padding(.bottom, .medium3)
						}
						.scrollIndicators(.never)
						.coordinateSpace(name: View.coordSpace)
					}
					.background {
						if viewStore.showEmptyState {
							Text(L10n.TransactionHistory.noTransactions)
								.textStyle(.sectionHeader)
								.foregroundStyle(.app.gray2)
						}
					}
					.background(.app.gray5)
					.overlayPreferenceValue(PositionsPreferenceKey.self, alignment: .top) { positions in
						let rect = positions[View.accountDummy]
						ZStack(alignment: .top) {
							if let rect {
								accountHeader
									.offset(y: rect.minY)
							}

							let scrollBarOffset = max(rect?.maxY ?? 0, 0)
							VStack(spacing: .small2) {
								HScrollBar(items: viewStore.periods, selection: selection)

								if let filters = viewStore.activeFilters.nilIfEmpty {
									ActiveFiltersView(filters: filters) { id in
										store.send(.view(.filterCrossTapped(id)), animation: .default)
									}
								}
							}
							.padding(.top, .small2)
							.padding(.bottom, .small1)
							.background(.app.white)
							.offset(y: scrollBarOffset)
						}
					}
					.clipShape(Rectangle())
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
			.ignoresSafeArea(edges: .bottom)
		}

		private static let coordSpace = "TransactionHistory"
		private static let accountDummy = "SmallAccountCardDummy"
	}

	struct SectionView: SwiftUI.View {
		let section: TransactionHistory.State.TransactionSection

		var body: some SwiftUI.View {
			Section {
				ForEach(section.transactions, id: \.self) { transaction in
					TransactionView(transaction: transaction)
						.padding(.horizontal, .medium3)
				}
			} header: {
				SectionHeaderView(title: section.title)
			}
		}
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

		struct Dummy: SwiftUI.View {
			var body: some SwiftUI.View {
				Text("DUMMY")
					.textStyle(.body1HighImportance)
					.foregroundStyle(.clear)
					.padding(.vertical, .small2)
			}
		}
	}

	struct SectionHeaderView: SwiftUI.View {
		let title: String

		var body: some SwiftUI.View {
			Text(title)
				.textStyle(.body2Header)
				.foregroundStyle(.app.gray2)
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small2)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.app.gray5)
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

// MARK: - TransactionHistory.TransactionView
extension TransactionHistory {
	struct TransactionView: SwiftUI.View {
		let transaction: TransactionHistoryItem

		init(transaction: TransactionHistoryItem) {
			self.transaction = transaction
		}

		var body: some SwiftUI.View {
			Card(.app.white) {
				VStack(spacing: 0) {
					if let message = transaction.message {
						MessageView(message: message)
							.padding(.bottom, -.small3)
					}

					VStack(spacing: .small1) {
						if transaction.failed {
							FailedTransactionView()
						} else if transaction.isEmpty {
							EmptyTransactionView()
						} else {
							if !transaction.withdrawals.isEmpty {
								let resources = transaction.withdrawals.map(\.viewState)
								TransfersActionView(type: .withdrawal, resources: resources)
							}

							if !transaction.deposits.isEmpty {
								let resources = transaction.deposits.map(\.viewState)
								TransfersActionView(type: .deposit, resources: resources)
							}

							if transaction.depositSettingsUpdated {
								DepositSettingsActionView()
							}
						}
					}
					.overlay(alignment: .topTrailing) {
						TimeStampView(manifestClass: transaction.manifestClass, time: transaction.time)
					}
					.padding(.top, .small1)
					.padding(.horizontal, .medium3)
				}
				.padding(.bottom, .medium3)
			}
		}

		var time: Date {
			transaction.time
		}

		var manifestClass: GatewayAPI.ManifestClass? {
			transaction.manifestClass
		}

		struct MessageView: SwiftUI.View {
			let message: String

			var body: some SwiftUI.View {
				let inset: CGFloat = 2
				Text(message)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray1)
					.padding(.medium3)
					.frame(maxWidth: .infinity, alignment: .leading)
					.inFlatBottomSpeechbubble(inset: inset)
					.padding(.top, inset)
					.padding(.horizontal, inset)
			}
		}

		struct TimeStampView: SwiftUI.View {
			let manifestClass: GatewayAPI.ManifestClass?
			let time: Date

			var body: some SwiftUI.View {
				Text("\(manifestClassLabel) • \(timeLabel)")
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
			}

			private var manifestClassLabel: String {
				TransactionHistory.label(for: manifestClass)
			}

			private var timeLabel: String {
				time.formatted(date: .omitted, time: .shortened)
			}
		}

		struct TransfersActionView: SwiftUI.View {
			let type: TransferType
			let resources: [ResourceBalance.ViewState]

			enum TransferType {
				case withdrawal
				case deposit
			}

			var body: some SwiftUI.View {
				VStack {
					switch type {
					case .withdrawal:
						EventHeader(event: .withdrawn)
					case .deposit:
						EventHeader(event: .deposited)
					}

					ResourceBalancesView(resources)
						.environment(\.resourceBalanceHideDetails, true)
				}
			}
		}

		struct DepositSettingsActionView: SwiftUI.View {
			var body: some SwiftUI.View {
				VStack {
					EventHeader(event: .settings)

					Text(L10n.TransactionHistory.updatedDepositSettings)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
						.flushedLeft
						.padding(.small1)
						.roundedCorners(strokeColor: .app.gray3)
				}
			}
		}

		struct FailedTransactionView: SwiftUI.View {
			var body: some SwiftUI.View {
				VStack {
					EventHeader.Dummy()

					HStack(spacing: .small2) {
						Image(.warningError)
							.resizable()
							.frame(.smallest)
							.tint(.app.notification)

						Text(L10n.TransactionHistory.failedTransaction)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.notification)

						Spacer(minLength: 0)
					}
					.padding(.horizontal, .small1)
					.padding(.vertical, .medium3)
					.roundedCorners(strokeColor: .app.gray3)
				}
			}
		}

		struct EmptyTransactionView: SwiftUI.View {
			var body: some SwiftUI.View {
				VStack {
					EventHeader.Dummy()

					Text(L10n.TransactionHistory.noBalanceChanges)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
						.flushedLeft
						.padding(.small1)
						.roundedCorners(strokeColor: .app.gray3)
				}
			}
		}

		struct EventHeader: SwiftUI.View {
			let event: Event

			var body: some SwiftUI.View {
				HStack(spacing: .zero) {
					Image(image)
						.padding(.trailing, .small3)

					Text(label)
						.textStyle(.body2Header)
						.foregroundColor(textColor)

					Spacer()
				}
			}

			private var image: ImageResource {
				switch event {
				case .deposited:
					.transactionHistoryDeposit
				case .withdrawn:
					.transactionHistoryWithdrawal
				case .settings:
					.transactionHistorySettings
				}
			}

			private var label: String {
				switch event {
				case .deposited:
					L10n.TransactionHistory.depositedSection
				case .withdrawn:
					L10n.TransactionHistory.withdrawnSection
				case .settings:
					L10n.TransactionHistory.settingsSection
				}
			}

			private var textColor: Color {
				switch event {
				case .deposited:
					.app.green1
				case .withdrawn, .settings:
					.app.gray1
				}
			}

			struct Dummy: SwiftUI.View {
				var body: some SwiftUI.View {
					Text("DUMMY")
						.textStyle(.body2Header)
						.foregroundColor(.clear)
				}
			}
		}
	}

	public enum Event {
		case deposited
		case withdrawn
		case settings
	}
}

// MARK: - ScrollBarItem
public protocol ScrollBarItem: Identifiable {
	var caption: String { get }
}

// MARK: - DateRangeItem
public struct DateRangeItem: ScrollBarItem, Sendable, Hashable {
	public var id: Date { startDate }
	public let caption: String
	let startDate: Date
	let endDate: Date
	var range: Range<Date> { startDate ..< endDate }
}

// MARK: - HScrollBar
public struct HScrollBar<Item: ScrollBarItem>: View {
	let items: [Item]
	@Binding var selection: Item.ID

	public var body: some View {
		ScrollView(.horizontal) {
			HStack(spacing: .zero) {
				ForEach(items) { item in
					let isSelected = item.id == selection
					Button {
						selection = item.id
					} label: {
						Text(item.caption.localizedUppercase)
							.foregroundStyle(isSelected ? .app.gray1 : .app.gray2)
					}
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small2)
					.measurePosition(item.id, coordSpace: HScrollBar.coordSpace)
					.padding(.horizontal, .small3)
					.animation(.default, value: isSelected)
				}
			}
			.coordinateSpace(name: HScrollBar.coordSpace)
			.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
				if let rect = positions[selection] {
					Capsule()
						.fill(.app.gray4)
						.frame(width: rect.width, height: rect.height)
						.position(x: rect.midX, y: rect.midY)
						.animation(.default, value: rect)
				}
			}
			.padding(.horizontal, .medium3)
		}
		.scrollIndicators(.never)
	}

	private static var coordSpace: String { "HScrollBar.HStack" }
}

// MARK: - HScrollBarDummy
public struct HScrollBarDummy: View {
	public var body: some View {
		Text("DUMMY")
			.foregroundStyle(.clear)
			.padding(.vertical, .small2)
			.frame(maxWidth: .infinity)
	}
}

extension View {
	public func measurePosition(_ id: AnyHashable, coordSpace: String) -> some View {
		background {
			GeometryReader { proxy in
				Color.clear
					.preference(key: PositionsPreferenceKey.self, value: [id: proxy.frame(in: .named(coordSpace))])
			}
		}
	}
}

// MARK: - PositionsPreferenceKey
private enum PositionsPreferenceKey: PreferenceKey {
	static var defaultValue: [AnyHashable: CGRect] = [:]

	static func reduce(value: inout [AnyHashable: CGRect], nextValue: () -> [AnyHashable: CGRect]) {
		value.merge(nextValue()) { $1 }
	}
}

extension TransactionHistory.State.TransactionSection {
	var title: String {
		day.formatted(date: .abbreviated, time: .omitted)
	}
}

extension View {
	public func measureSize(_ id: AnyHashable) -> some View {
		background {
			GeometryReader { proxy in
				Color.clear
					.preference(key: PositionsPreferenceKey.self, value: [id: proxy.frame(in: .local)])
			}
		}
	}

	public func readSize(_ id: AnyHashable, content: @escaping (CGSize) -> some View) -> some View {
		overlayPreferenceValue(PositionsPreferenceKey.self, alignment: .top) { positions in
			if let size = positions[id]?.size {
				content(size)
			} else {
				EmptyView()
			}
		}
	}

	public func onReadSize(_ id: AnyHashable, content: @escaping (CGSize) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let size = positions[id]?.size {
				content(size)
			}
		}
	}

	public func onReadSizes(_ id1: AnyHashable, _ id2: AnyHashable, content: @escaping (CGSize, CGSize) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let size1 = positions[id1]?.size, let size2 = positions[id2]?.size {
				content(size1, size2)
			}
		}
	}
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
