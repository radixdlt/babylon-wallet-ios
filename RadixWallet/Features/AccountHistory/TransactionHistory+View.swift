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
					let accountHeader = AccountHeaderView(account: viewStore.account)

					let selection = viewStore.binding(get: \.currentMonth, send: ViewAction.selectedMonth)

					VStack(spacing: .zero) {
						accountHeader

						VStack(spacing: .small2) {
							HScrollBar(items: viewStore.availableMonths, selection: selection)

							if let filters = viewStore.activeFilters.nilIfEmpty {
								ActiveFiltersView(filters: filters) { id in
									store.send(.view(.filterCrossTapped(id)), animation: .default)
								}
							}
						}
						.padding(.top, .small2)
						.padding(.bottom, .small1)
						.background(.app.white)

						TransactionsTableView(
							sections: viewStore.sections,
							scrollTarget: viewStore.scrollTarget
						) { action in
							store.send(.view(.transactionsTableAction(action)))
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
		let section: TransactionHistory.TransactionSection
		let onTap: (TXID) -> Void

		var body: some SwiftUI.View {
			Section {
				ForEach(section.transactions, id: \.self) { transaction in
					TransactionView(transaction: transaction)
						.onTapGesture {
							onTap(transaction.id)
						}
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
							.renderingMode(.template)
							.resizable()
							.frame(.smallest)

						Text(L10n.TransactionHistory.failedTransaction)
							.textStyle(.body2HighImportance)

						Spacer(minLength: 0)
					}
					.foregroundColor(.app.red1)
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
						.multilineTextAlignment(.leading)
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
		ScrollViewReader { proxy in
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
			.onChange(of: selection) { value in
				withAnimation {
					proxy.scrollTo(value, anchor: .center)
				}
			}
		}
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

extension TransactionHistory.TransactionSection {
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

	public func onReadPosition(_ id: AnyHashable, action: @escaping (CGRect) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let position = positions[id] {
				action(position)
			}
		}
	}

	public func onReadSizes(_ id1: AnyHashable, _ id2: AnyHashable, action: @escaping (CGSize, CGSize) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let size1 = positions[id1]?.size, let size2 = positions[id2]?.size {
				action(size1, size2)
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

// MARK: - TransactionHistory.TransactionsTableView
extension TransactionHistory {
	public struct TransactionsTableView: UIViewRepresentable {
		public enum Action: Hashable, Sendable {
			case transactionTapped(TXID)
			case pulledDown
			case nearingTop
			case nearingBottom
			case reachedBottom
			case monthChanged(Date)
		}

		public struct ScrollTarget: Hashable, Sendable {
			let transaction: TXID
			let topPosition: Bool
		}

		let sections: IdentifiedArrayOf<TransactionSection>
		let scrollTarget: ScrollTarget?
		let action: (Action) -> Void

		private static let cellIdentifier = "TransactionCell"

		public func makeUIView(context: Context) -> UITableView {
			let tableView = UITableView(frame: .zero, style: .plain)
			tableView.backgroundColor = .clear
			tableView.separatorStyle = .none
			tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
			tableView.delegate = context.coordinator
			tableView.dataSource = context.coordinator
			tableView.sectionHeaderTopPadding = 0

			return tableView
		}

		public func updateUIView(_ uiView: UITableView, context: Context) {
			let oldSections = context.coordinator.sections
			let sectionsIDs = sections.ids == oldSections.ids
			let txIDs = sections.allTransactions == oldSections.allTransactions
			print(" •• updateUIView: #\(oldSections.count).\(oldSections.allTransactions.count) -> #\(sections.count).\(sections.allTransactions.count). same sections: \(sections == oldSections), sectionIDs: \(sectionsIDs), txIDs: \(txIDs)")

			guard !sections.isEmpty, sections != context.coordinator.sections else { return }
			context.coordinator.sections = sections
			uiView.reloadData()

			if let scrollTarget, let indexPath = context.coordinator.sections.indexPath(for: scrollTarget.transaction) {
				print(" •• schould scroll to \(indexPath)")
//				uiView.scrollToRow(at: indexPath, at: scrollTarget.topPosition ? .top : .bottom, animated: false)
			}
		}

		public func makeCoordinator() -> Coordinator {
			Coordinator(sections: sections, action: action)
		}

		public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
			var sections: IdentifiedArrayOf<TransactionSection>
			let action: (Action) -> Void

			private var isScrolledPastTop: Bool = false

			private var previousCell: IndexPath = .init(row: 0, section: 0)

			private var month: Date = .distantPast

			private var scrolling: (direction: Direction, count: Int) = (.down, 0)

			public init(
				sections: IdentifiedArrayOf<TransactionSection>,
				action: @escaping (Action) -> Void
			) {
				self.sections = sections
				self.action = action
			}

			public func numberOfSections(in tableView: UITableView) -> Int {
				sections.count
			}

			public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
				let section = sections[section]

				let headerView = TransactionHistory.SectionHeaderView(title: section.title)
				let hostingController = UIHostingController(rootView: headerView)
				hostingController.view.backgroundColor = .clear
				hostingController.view.sizeToFit()

				return hostingController.view
			}

			public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
				sections[section].transactions.count
			}

			public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
				let cell = tableView.dequeueReusableCell(withIdentifier: TransactionsTableView.cellIdentifier, for: indexPath)
				let item = sections[indexPath.section].transactions[indexPath.row]

				cell.backgroundColor = .clear
				cell.contentConfiguration = UIHostingConfiguration { [weak self] in
					Button {
						self?.action(.transactionTapped(item.id))
					} label: {
						TransactionHistory.TransactionView(transaction: item)
					}
				}
				cell.selectionStyle = .none

				return cell
			}

			public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
				UITableView.automaticDimension
			}

			public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
				let section = sections[indexPath.section]
				let txID = section.transactions[indexPath.row].id
				let scrollDirection: Direction = indexPath > previousCell ? .down : .up
				if scrollDirection == scrolling.direction {
					scrolling.count += 1
				} else {
					scrolling = (scrollDirection, 0)
				}
				previousCell = indexPath

				// We only want to pre-emptively load if they have been scrolling for a while in the same direction
				if scrolling.count > 8 {
					let transactions = sections.allTransactions
					if scrolling.direction == .down, transactions.suffix(15).contains(txID) {
						action(.nearingBottom)
						scrolling.count = 0
					} else if scrollDirection == .up, transactions.prefix(7).contains(txID) {
						action(.nearingTop)
						scrolling.count = 0
					}
				} else if scrollDirection == .down, txID == sections.allTransactions.last {
					action(.reachedBottom)
				}
			}

			public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
				nil
			}

			// UIScrollViewDelegate

			public func scrollViewDidScroll(_ scrollView: UIScrollView) {
				if let tableView = scrollView as? UITableView {
					updateMonth(tableView: tableView)
				}

				if scrollView.contentOffset.y < -130, !isScrolledPastTop {
					action(.pulledDown)
					isScrolledPastTop = true
				} else if isScrolledPastTop, scrollView.contentOffset.y >= 0 {
					isScrolledPastTop = false
				}
			}

			// Helpers

			private func updateMonth(tableView: UITableView) {
				guard let topMost = tableView.indexPathsForVisibleRows?.first else { return }
				let newMonth = sections[topMost.section].month
				guard newMonth != month else { return }
				action(.monthChanged(newMonth))
				month = newMonth
			}
		}
	}
}

extension Collection where Element: Equatable {
	func hasPrefix(_ elements: some Collection<Element>) -> Bool {
		prefix(elements.count).elementsEqual(elements)
	}

	func hasSuffix(_ elements: some Collection<Element>) -> Bool {
		suffix(elements.count).elementsEqual(elements)
	}

	/// When the start of this collection overlaps the end of the other, returns the length of this overlap, otherwise `nil`
	func prefixOverlappingSuffix(of elements: some Collection<Element>) -> Int? {
		guard let first, let index = elements.reversed().firstIndex(of: first) else { return nil }
		guard elements.hasSuffix(prefix(index + 1)) else { return nil }
		return index + 1
	}
}

extension IdentifiedArrayOf<TransactionHistory.TransactionSection> {
	var allTransactions: [TXID] {
		flatMap(\.transactions.ids)
	}

	func transaction(for indexPath: IndexPath) -> TXID {
		self[indexPath.section].transactions[indexPath.row].id
	}

	func indexPath(for transaction: TXID) -> IndexPath? {
		for (index, section) in enumerated() {
			if let row = section.transactions.ids.firstIndex(of: transaction) {
				return .init(row: row, section: index)
			}
		}

		return nil
	}
}
