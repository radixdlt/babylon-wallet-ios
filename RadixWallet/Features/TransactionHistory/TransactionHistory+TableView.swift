import SwiftUI

// MARK: - TransactionHistory.TableView
extension TransactionHistory {
	struct TableView: UIViewRepresentable {
		enum Action: Hashable, Sendable {
			case transactionTapped(TransactionIntentHash)
			case reachedTop
			case pulledDown
			case nearingBottom
			case reachedBottom
			case monthChanged(Date)
		}

		let sections: IdentifiedArrayOf<TransactionSection>
		let scrollTarget: Triggering<TransactionIntentHash?>
		let action: (Action) -> Void

		private static let cellIdentifier = "TransactionCell"

		func makeUIView(context: Context) -> UITableView {
			let tableView = UITableView(frame: .zero, style: .plain)
			tableView.backgroundColor = .clear
			tableView.separatorStyle = .none
			tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
			tableView.delegate = context.coordinator
			tableView.dataSource = context.coordinator
			tableView.sectionHeaderTopPadding = 0

			return tableView
		}

		func updateUIView(_ uiView: UITableView, context: Context) {
			if !sections.isEmpty, sections != context.coordinator.sections {
				context.coordinator.sections = sections
				uiView.reloadData()
			}

			if let scrollTarget = scrollTarget.value, let indexPath = context.coordinator.sections.indexPath(for: scrollTarget) {
				uiView.scrollToRow(at: indexPath, at: .top, animated: false)
				context.coordinator.didSelectMonth = true
			}
		}

		func makeCoordinator() -> Coordinator {
			Coordinator(sections: sections, action: action)
		}

		class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
			var didSelectMonth: Bool = false

			var sections: IdentifiedArrayOf<TransactionSection>
			let action: (Action) -> Void

			private var isPulledDown: Bool = false
			private var isNearingBottom: Bool = false

			private var month: Date = .distantPast

			init(
				sections: IdentifiedArrayOf<TransactionSection>,
				action: @escaping (Action) -> Void
			) {
				self.sections = sections
				self.action = action
			}

			func numberOfSections(in tableView: UITableView) -> Int {
				sections.count
			}

			func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
				let section = sections[section]

				let headerView = TransactionHistory.SectionHeaderView(title: section.title)
				let hostingController = UIHostingController(rootView: headerView)
				hostingController.view.sizeToFit()

				return hostingController.view
			}

			func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
				sections[section].transactions.count
			}

			func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
				let cell = tableView.dequeueReusableCell(withIdentifier: TableView.cellIdentifier, for: indexPath)
				let item = sections[indexPath.section].transactions[indexPath.row]

				cell.backgroundColor = .init(.app.gray5)
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

			func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
				UITableView.automaticDimension
			}

			func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
				nil
			}

			// UIScrollViewDelegate

			func scrollViewDidScroll(_ scrollView: UIScrollView) {
				guard let tableView = scrollView as? UITableView else {
					assertionFailure("This should be a UITableView")
					return
				}

				updateMonth(tableView: tableView)

				let offset = scrollView.contentOffset.y

				// Detect pull to refresh

				if offset < -20, !isPulledDown {
					action(.pulledDown)
					isPulledDown = true
				} else if offset >= 0, isPulledDown {
					isPulledDown = false
				}

				// Detect if we are getting close to the bottom

				let isClose = isCloseToBottom(tableView: tableView) && scrollView.isDragging
				if isClose, !isNearingBottom {
					action(.nearingBottom)
					isNearingBottom = true
				} else if !isClose, isNearingBottom {
					isNearingBottom = false
				}
			}

			func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
				didSelectMonth = false
			}

			func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
				guard let tableView = scrollView as? UITableView else {
					assertionFailure("This should be a UITableView")
					return
				}

				if isAtTop(tableView: tableView) {
					action(.reachedTop)
				} else if isCloseToBottom(tableView: tableView) {
					action(.reachedBottom)
				}
			}

			// Helpers

			private func isAtTop(tableView: UITableView) -> Bool {
				guard let visibleRows = tableView.indexPathsForVisibleRows else { return false }
				return visibleRows.contains(.firstRow)
			}

			private func isCloseToBottom(tableView: UITableView) -> Bool {
				guard let lastVisible = tableView.indexPathsForVisibleRows?.last else { return false }
				return sections.allTransactions.suffix(5).contains(sections.transaction(for: lastVisible).id)
			}

			private func updateMonth(tableView: UITableView) {
				// If the user hasn't scrolled since selecting a month, we won't update the month
				guard !didSelectMonth, let topMost = tableView.indexPathsForVisibleRows?.first else { return }
				let newMonth = sections[topMost.section].month
				guard newMonth != month else { return }
				month = newMonth

				Task {
					action(.monthChanged(newMonth))
				}
			}
		}
	}
}

extension TransactionHistoryItem {
	var isEmpty: Bool {
		manifestClass != .accountDepositSettingsUpdate && deposits.isEmpty && withdrawals.isEmpty
	}

	var isComplex: Bool {
		manifestClass == nil
	}
}

// MARK: - TransactionHistory.TransactionView
extension TransactionHistory {
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

	struct TransactionView: SwiftUI.View {
		let transaction: TransactionHistoryItem

		init(transaction: TransactionHistoryItem) {
			self.transaction = transaction
		}

		var body: some SwiftUI.View {
			Card(.app.white) {
				VStack(spacing: 0) {
					if let message = transaction.message, !message.isEmpty {
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
								let resources = transaction.withdrawals.map(\.toResourceBalance.viewState)
								TransfersActionView(type: .withdrawal, resources: resources)
							}

							if !transaction.deposits.isEmpty {
								let resources = transaction.deposits.map(\.toResourceBalance.viewState)
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
					.padding(.bottom, .medium3)

//					if transaction.isComplex {
//						ComplexTransactionView()
//					}
				}
			}
		}

		var time: Date {
			transaction.time
		}

		var manifestClass: GatewayAPI.ManifestClass? {
			transaction.manifestClass
		}

		struct MessageView: SwiftUI.View {
			@SwiftUI.State private var fullHeight: CGFloat = .zero
			@SwiftUI.State private var collapsedHeight: CGFloat = .zero
			@SwiftUI.State private var isCollapsed: Bool = true

			let message: String

			private let collapsedLineLimit: Int = 1
			private let spacing: CGFloat = .small1

			var body: some SwiftUI.View {
				let inset: CGFloat = 2
				ExpandableTextView(fullText: message, lineLimit: 2)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.leading)
					.padding(.medium3)
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
						Image(.error)

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

		struct ComplexTransactionView: SwiftUI.View {
			var body: some SwiftUI.View {
				let inset: CGFloat = 2
				Text(L10n.TransactionHistory.complexTransaction)
					.multilineTextAlignment(.leading)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray2)
					.padding(.vertical, .small2)
					.padding(.horizontal, .medium3)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(.app.gray5)
					.roundedCorners(.bottom, radius: .medium3 - inset)
					.padding(.horizontal, inset)
					.padding(.bottom, inset)
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

	enum Event {
		case deposited
		case withdrawn
		case settings
	}
}

extension IndexPath {
	static let firstRow: IndexPath = .init(row: 0, section: 0)
}

extension IdentifiedArrayOf<TransactionHistory.TransactionSection> {
	var allTransactions: [TransactionIntentHash] {
		flatMap(\.transactions.ids)
	}

	func transaction(for indexPath: IndexPath) -> TransactionHistoryItem {
		self[indexPath.section].transactions[indexPath.row]
	}

	func indexPath(for transaction: TransactionIntentHash) -> IndexPath? {
		for (index, section) in enumerated() {
			if let row = section.transactions.ids.firstIndex(of: transaction) {
				return .init(row: row, section: index)
			}
		}

		return nil
	}
}

extension TransactionHistory.TransactionSection {
	var title: String {
		Self.string(from: day)
	}

	private static func string(from date: Date) -> String {
		let calendar: Calendar = .current

		if calendar.areSameYear(date, .now) {
			let dateString = date.formatted(.dateTime.day().month(.wide))
			if calendar.isDateInToday(date) {
				return "\(L10n.TransactionHistory.DatePrefix.today), \(dateString)"
			} else if calendar.isDateInYesterday(date) {
				return "\(L10n.TransactionHistory.DatePrefix.yesterday), \(dateString)"
			} else {
				return dateString
			}
		} else {
			return date.formatted(.dateTime.day().month(.wide).year())
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
