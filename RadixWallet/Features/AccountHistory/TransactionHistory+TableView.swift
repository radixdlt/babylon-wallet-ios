import SwiftUI

// MARK: - TransactionHistory.TableView
extension TransactionHistory {
	public struct TableView: UIViewRepresentable {
		public enum Action: Hashable, Sendable {
			case transactionTapped(TXID)
			case pulledDown
			case nearingTop
			case nearingBottom
			case reachedBottom
			case monthChanged(Date)
		}

		let sections: IdentifiedArrayOf<TransactionSection>
		let scrollTarget: TXID?
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
			guard !sections.isEmpty, sections != context.coordinator.sections else { return }
			context.coordinator.sections = sections
			uiView.reloadData()

			if let scrollTarget, let indexPath = context.coordinator.sections.indexPath(for: scrollTarget) {
				uiView.scrollToRow(at: indexPath, at: .top, animated: false)
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

				if scrollView.contentOffset.y < -20, !isScrolledPastTop {
					action(.pulledDown)
					isScrolledPastTop = true
				} else if isScrolledPastTop, scrollView.contentOffset.y >= 0 {
					isScrolledPastTop = false
				}
			}

			// Helpers

			func updateMonth(tableView: UITableView) {
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
