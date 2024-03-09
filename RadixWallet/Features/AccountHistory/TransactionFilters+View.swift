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
			NavigationStack {
				ScrollView {
					WithViewStore(store, observe: \.filters, send: { .view($0) }) { viewStore in
						VStack(spacing: .medium3) {
							HStack(spacing: .small1) {
								FiltersView(filters: viewStore.transferTypes, store: store)

								Spacer(minLength: 0)
							}

							Divider()

							if viewStore.showAssetsSection {
								Section("Type of asset") { // FIXME: Strings
									SubSection("Tokens", filters: viewStore.fungibles, labels: tokenLabels, store: store)

									Divider()

									SubSection("NFTs", filters: viewStore.nonFungibles, labels: nftLabels, store: store)
								}

								Divider()
							}

							Section("Type of transaction") {
								SubSection(filters: viewStore.transactionTypes, store: store)
							}

							Divider()

							Spacer(minLength: 0)
						}
						.padding(.horizontal, .medium1)
					}
				}
				.footer {
					Button("Show results") {
						store.send(.view(.showResultsTapped))
					}
					.buttonStyle(.primaryRectangular(shouldExpand: true))
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						CloseButton {
							store.send(.view(.closeTapped))
						}
					}
					ToolbarItem(placement: .topBarTrailing) {
						Button("Clear all") { // FIXME: Strings
							store.send(.view(.clearTapped))
						}
					}
				}
			}
		}

		private var tokenLabels: SubSection.FlexibleLabels {
			.init(showAll: "Show all tokens", showLess: "Show fewer tokens") // FIXME: Strings
		}

		private var nftLabels: SubSection.FlexibleLabels {
			.init(showAll: "Show all NFTs", showLess: "Show fewer NFTs") // FIXME: Strings
		}

		struct Section<Content: SwiftUI.View>: SwiftUI.View {
			@SwiftUI.State private var expanded: Bool = false
			let name: String
			let content: Content

			init(_ name: String, @ViewBuilder content: () -> Content) {
				self.name = name
				self.content = content()
			}

			var body: some SwiftUI.View {
				VStack(spacing: 0) {
					Button {
						withAnimation(.default) {
							expanded.toggle()
						}
					} label: {
						HStack(spacing: .zero) {
							Text(name)
								.textStyle(.body1Header)
								.foregroundStyle(.app.gray1)
								.padding(.vertical, .small2)

							Spacer()

							Image(expanded ? .chevronUp : .chevronDown)
						}
					}
					.background(.app.white)

					if expanded {
						content
							.padding(.top, .medium3)
					}
				}
				.clipped()
			}
		}

		struct SubSection: SwiftUI.View {
			struct FlexibleLabels: Equatable {
				let showAll: String
				let showLess: String
			}

			@SwiftUI.State private var rowHeight: CGFloat = .infinity
			@SwiftUI.State private var totalHeight: CGFloat = .infinity
			@SwiftUI.State private var isCollapsed: Bool = true

			let heading: String?
			let filters: IdentifiedArrayOf<State.Filter>
			let labels: FlexibleLabels?
			let store: StoreOf<TransactionHistoryFilters>

			private var showCollapseButton: Bool {
				labels != nil && totalHeight > collapsedHeight
			}

			private var collapsedHeight: CGFloat {
				CGFloat(collapsedRowLimit) * rowHeight + CGFloat(collapsedRowLimit - 1) * spacing
			}

			private let collapsedRowLimit: Int = 2
			private let spacing: CGFloat = .small1

			init(_ heading: String? = nil, filters: IdentifiedArrayOf<State.Filter>, labels: FlexibleLabels? = nil, store: StoreOf<TransactionHistoryFilters>) {
				self.heading = heading
				self.filters = filters
				self.labels = labels
				self.store = store
			}

			var body: some SwiftUI.View {
				if !filters.isEmpty {
					VStack(spacing: .zero) {
						if let heading {
							Text(heading)
								.textStyle(.body1HighImportance)
								.foregroundStyle(.app.gray2)
								.flushedLeft
								.padding(.bottom, .medium3)
						}

						HStack(spacing: .zero) {
							FlowLayout(spacing: spacing) {
								FiltersView(filters: filters, store: store)
							}
							.measureSize(flowLayoutID)
							.overlay {
								TransactionFilterView.Dummy()
									.measureSize(flowDummyID)
							}

							Spacer(minLength: 0)
						}
						.frame(maxHeight: isCollapsed ? collapsedHeight : .infinity, alignment: .top)
						.clipped()
						.onReadSizes(flowDummyID, flowLayoutID) { dummySize, flowSize in
							rowHeight = dummySize.height
							totalHeight = flowSize.height
						}

						if showCollapseButton, let labels {
							Button {
								withAnimation {
									isCollapsed.toggle()
								}
							} label: {
								ZStack {
									Text("+ \(labels.showAll)")
										.opacity(isCollapsed ? 1 : 0)
									Text("- \(labels.showLess)")
										.opacity(isCollapsed ? 0 : 1)
								}
							}
							.buttonStyle(.blueText)
							.padding(.top, .medium3)
						}
					}
					.animation(.default, value: isCollapsed)
				}
			}

			private let flowLayoutID = "FlowLayout"
			private let flowDummyID = "FlowDummy"
		}

		private struct FiltersView: SwiftUI.View {
			let filters: IdentifiedArrayOf<State.Filter>
			let store: StoreOf<TransactionHistoryFilters>

			var body: some SwiftUI.View {
				ForEach(filters) { filter in
					TransactionFilterView(filter: filter) { id in
						store.send(.view(.filterTapped(id)))
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
	var crossAction: ((TransactionFilter) -> Void)? = nil

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
		.disabled(showCross)
		.padding(.trailing, showCross ? .medium1 : 0)
		.background {
			ZStack {
				Capsule().fill(filter.isActive ? .app.gray1 : .app.white)
				Capsule().stroke(filter.isActive ? .clear : .app.gray3)
			}
		}
		.overlay(alignment: .trailing) {
			if showCross, let crossAction {
				Button(asset: AssetResource.close) {
					crossAction(filter.id)
				}
				.tint(.app.gray3)
				.padding(.vertical, -.small3)
				.padding(.trailing, .small2)
				.transition(.scale.combined(with: .opacity))
			}
		}
		.animation(.default.speed(2), value: filter.isActive)
	}

	private var showCross: Bool {
		crossAction != nil && filter.isActive
	}

	private var textColor: Color {
		filter.isActive ? .app.white : .app.gray1
	}

	struct Dummy: SwiftUI.View {
		var body: some SwiftUI.View {
			Text("ABC")
				.textStyle(.body1HighImportance)
				.foregroundStyle(.clear)
				.padding(.vertical, .small2)
		}
	}
}
