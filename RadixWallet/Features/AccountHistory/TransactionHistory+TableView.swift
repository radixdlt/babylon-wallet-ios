import SwiftUI

// MARK: - TransactionHistory.TableView
extension TransactionHistory {
	public struct TableView: UIViewRepresentable {
		public enum Action: Hashable, Sendable {
			case transactionTapped(TXID)
			case reachedTop
			case pulledDown
			case nearingBottom
			case reachedBottom
			case monthChanged(Date)
		}

		let sections: IdentifiedArrayOf<TransactionSection>
		let scrollTarget: Triggering<TXID?>
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
			if !sections.isEmpty, sections != context.coordinator.sections {
				context.coordinator.sections = sections
				uiView.reloadData()
			}

			if let scrollTarget = scrollTarget.value, let indexPath = context.coordinator.sections.indexPath(for: scrollTarget) {
				uiView.scrollToRow(at: indexPath, at: .top, animated: false)
			}
		}

		public func makeCoordinator() -> Coordinator {
			Coordinator(sections: sections, action: action)
		}

		public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
			var sections: IdentifiedArrayOf<TransactionSection>
			let action: (Action) -> Void

			private var isPulledDown: Bool = false
			private var isNearingBottom: Bool = false

			private var month: Date = .distantPast

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
				hostingController.view.sizeToFit()

				return hostingController.view
			}

			public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
				sections[section].transactions.count
			}

			public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

			public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
				UITableView.automaticDimension
			}

			public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
				nil
			}

			// UIScrollViewDelegate

			public func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

			public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
				return sections.allTransactions.suffix(5).contains(sections.transaction(for: lastVisible))
			}

			private func updateMonth(tableView: UITableView) {
				guard let topMost = tableView.indexPathsForVisibleRows?.first else { return }
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

extension IndexPath {
	static let firstRow: IndexPath = .init(row: 0, section: 0)
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
