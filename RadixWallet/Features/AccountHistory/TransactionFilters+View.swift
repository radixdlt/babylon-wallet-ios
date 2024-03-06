import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistoryFilters.View
extension TransactionHistoryFilters {
	public typealias ViewState = State.Filters

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistoryFilters>

		public init(store: StoreOf<TransactionHistoryFilters>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				WithViewStore(store, observe: \.filters, send: { .view($0) }) { viewStore in
					VStack {
						SubSection(filters: viewStore.transferTypes, flexible: false, store: store)

						if viewStore.showAssetsSection {
							Section("Type of asset") {
								SubSection("Tokens", filters: viewStore.fungibles, store: store)

								SubSection("NFTs", filters: viewStore.nonFungibles, store: store)
							}
						}

						Section("Type of transaction") {
							SubSection(filters: viewStore.transactionTypes, store: store)
						}

						Spacer(minLength: 0)
					}
					.padding(.horizontal, .medium1)
				}
			}
		}

		struct Section<Content: SwiftUI.View>: SwiftUI.View {
			@SwiftUI.State private var expanded: Bool = true
			let name: String
			let content: Content

			init(_ name: String, @ViewBuilder content: () -> Content) {
				self.name = name
				self.content = content()
			}

			var body: some SwiftUI.View {
				VStack(spacing: 0) {
					HStack(spacing: .zero) {
						Text(name)
							.textStyle(.body1Header)
							.foregroundStyle(.app.gray1)
							.padding(.vertical, .small2)

						Spacer()

						Button {
							withAnimation(.default) {
								expanded.toggle()
							}
						} label: {
							Image(expanded ? .chevronUp : .chevronDown)
						}
					}
					.background(.app.gray5)

					if expanded {
						content
					}
				}
				.clipped()
			}
		}

		struct SubSection: SwiftUI.View {
			let heading: String?
			let filters: IdentifiedArrayOf<State.Filter>
			let flexible: Bool
			let store: StoreOf<TransactionHistoryFilters>

			init(_ heading: String? = nil, filters: IdentifiedArrayOf<State.Filter>, flexible: Bool = true, store: StoreOf<TransactionHistoryFilters>) {
				self.heading = heading
				self.filters = filters
				self.flexible = flexible
				self.store = store
			}

			var body: some SwiftUI.View {
				if !filters.isEmpty {
					VStack {
						if let heading {
							Text(heading)
								.textStyle(.body1HighImportance)
								.foregroundStyle(.app.gray2)
						}

						HStack(spacing: .zero) {
							FlowLayout(spacing: .small1) {
								ForEach(filters) { filter in
									TransactionFilterView(filter: filter) { id in
										store.send(.view(.filterTapped(id)))
									}
								}
							}

							Spacer(minLength: 0)
						}
					}
				}
			}
		}
	}
}

// MARK: - TransactionFilterView
struct TransactionFilterView: SwiftUI.View {
	let filter: TransactionHistoryFilters.State.Filter
	let action: (TransactionFilter) -> Void

	var body: some SwiftUI.View {
		Button {
			action(filter.id)
		} label: {
			HStack(spacing: .small3) {
				if let icon = filter.icon {
					Image(icon)
						.tint(textColor)
				}

				Text(filter.label)
					.textStyle(.body1HighImportance)
					.foregroundStyle(textColor)
			}
			.padding(.vertical, .small2)
			.padding(.horizontal, .medium3)
		}
		.contentShape(Capsule())
		.background {
			ZStack {
				Capsule().fill(filter.isActive ? .app.gray1 : .app.white)
				Capsule().stroke(filter.isActive ? .clear : .app.gray3)
			}
		}
		.animation(.default.speed(2), value: filter.isActive)
	}

	private var textColor: Color {
		filter.isActive ? .app.white : .app.gray1
	}

	struct Dummy: SwiftUI.View {
		var body: some SwiftUI.View {
			Text("ABC")
				.textStyle(.body1HighImportance)
				.padding(.vertical, .small2)
		}
	}
}
