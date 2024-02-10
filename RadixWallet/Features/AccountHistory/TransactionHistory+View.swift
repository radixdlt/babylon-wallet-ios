import ComposableArchitecture
import SwiftUI

extension StoreOf<TransactionHistory> {
	static func transactionHistory(account: Profile.Network.Account) -> Store {
		Store(initialState: State(account: account)) {
			TransactionHistory()
		}
	}
}

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
					ScrollView {
						VStack(spacing: .zero) {
							SmallAccountCard(account: viewStore.account)
								.roundedCorners(radius: .small1)
								.padding(.horizontal, .medium3)
								.padding(.vertical, .medium3)

							HScrollBar(items: items, selection: $selection)
						}
					}
					.scrollIndicators(.never)
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						CloseButton {
							print("• close")
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
					.measurePosition(id: item.id, coordSpace: HScrollBar.coordSpace)
					.animation(.default, value: isSelected)
				}
			}
			.coordinateSpace(name: HScrollBar.coordSpace)
			.backgroundPreferenceValue(PositionPreferenceKey.self) { positions in
				if let rect = positions[selection] {
					Capsule()
						.fill(.app.gray4)
						.frame(width: rect.width, height: rect.height)
						.position(x: rect.midX, y: rect.midY)
						.animation(.default.speed(2), value: rect)
				}
			}
			.padding(.horizontal, .medium3)
		}
		.scrollIndicators(.never)
	}

	static let coordSpace = "HScrollBar.HStack"
}

extension View {
	public func measurePosition(id: UUID, coordSpace: String) -> some View {
		background {
			GeometryReader { proxy in
				Color.clear
					.preference(key: PositionPreferenceKey.self, value: [id: proxy.frame(in: .named(coordSpace))])
			}
		}
	}
}

// MARK: - PositionPreferenceKey
private enum PositionPreferenceKey: PreferenceKey {
	static var defaultValue: [UUID: CGRect] = [:]

	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue()) { $1 }
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
