import ComposableArchitecture
import SwiftUI

let items: [HScrollBar.Item] = [
	HScrollBar.Item(id: .init(), text: "Jan"),
	HScrollBar.Item(id: .init(), text: "Feb"),
	HScrollBar.Item(id: .init(), text: "Mar"),
	HScrollBar.Item(id: .init(), text: "Apr"),
	HScrollBar.Item(id: .init(), text: "May"),
	HScrollBar.Item(id: .init(), text: "Jun"),
	HScrollBar.Item(id: .init(), text: "Jul"),
	HScrollBar.Item(id: .init(), text: "Aug"),
	HScrollBar.Item(id: .init(), text: "Sep"),
]

// MARK: - TransactionHistory.View
extension TransactionHistory {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistory>

		@SwiftUI.State var selection: UUID = items[0].id

		public init(store: StoreOf<TransactionHistory>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
					let accountHeader = AccountHeaderView(account: viewStore.account)
					VStack(spacing: .zero) {
						HScrollBar.Dummy()
							.padding(.vertical, .small3)

						ScrollView {
							LazyVStack(spacing: .small1, pinnedViews: [.sectionHeaders]) {
								accountHeader
									.measurePosition(View.accountDummy, coordSpace: View.coordSpace)
									.opacity(0)

								ForEach(viewStore.sections) { section in
									SectionView(section: section)
								}
							}
						}
						.scrollIndicators(.never)
						.coordinateSpace(name: View.coordSpace)
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
							HScrollBar(items: items, selection: $selection)
								.padding(.vertical, .small3)
								.background(.app.white)
								.offset(y: scrollBarOffset)
						}
					}
					.clipShape(Rectangle())
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						CloseButton {
							store.send(.view(.closeTapped))
						}
					}
					ToolbarItem(placement: .topBarTrailing) {
						Button(asset: AssetResource.filterList) {}
					}
				}
				.navigationTitle("History")
				.navigationBarTitleDisplayMode(.inline)
			}
		}

		private static let coordSpace = "TransactionHistory"
		private static let accountDummy = "SmallAccountCardDummy"
	}

	struct SectionView: SwiftUI.View {
		let section: TransactionHistory.State.TransferSection

		var body: some SwiftUI.View {
			Section {
				ForEach(section.transfers, id: \.self) { transfer in
					Card(.app.white) {
						Text(transfer.string)
							.padding(.vertical, .small1)
							.frame(maxWidth: .infinity)
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

	struct SectionHeaderView: SwiftUI.View {
		let title: String

		var body: some SwiftUI.View {
			Text(title)
				.textStyle(.body2Header)
				.foregroundStyle(.app.gray2)
				.padding(.horizontal, .medium3)
				.padding(.top, .small1)
				.padding(.bottom, .small2)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.app.gray5)
		}
	}
}

// MARK: - HScrollBar
struct HScrollBar: View {
	struct Item: Identifiable {
		let id: UUID
		let text: String
	}

	let items: [Item]
	@Binding var selection: UUID

	var body: some View {
		ScrollView(.horizontal) {
			HStack(spacing: .zero) {
				ForEach(items) { item in
					let isSelected = item.id == selection
					Button {
						selection = item.id
					} label: {
						Text(item.text.localizedUppercase)
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
			.padding(.vertical, .small1)
			.padding(.horizontal, .medium3)
		}
		.scrollIndicators(.never)
	}

	private static let coordSpace = "HScrollBar.HStack"

	struct Dummy: View {
		var body: some View {
			Text("DUMMY")
				.foregroundStyle(.clear)
				.padding(.vertical, 2 * .small2)
				.frame(maxWidth: .infinity)
		}
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

// "ViewState"

extension TransactionHistory.State.TransferSection {
	var title: String {
		date.formatted(date: .abbreviated, time: .omitted)
	}
}

// struct DateBar: View {
//	let dates: [DateComponents]
//	let showYear: Bool
//
//	enum TimeUnit {
//		case year
//		case month
//		case day
//	}
//
//	init(_ steps: Int, unit: Calendar.Component) {
//		let today = Date.now
//		let calendar = Calendar.current
//		switch unit {
//		case .year:
//			let last = calendar.dat
//			<#code#>
//		case .month:
//			<#code#>
//		case .day:
//			<#code#>
//		}
//	}
//
//	var body: some View {
//		ScrollView(.horizontal) {
//			Text("")
//		}
//		.scrollIndicators(.never)
//	}
// }
