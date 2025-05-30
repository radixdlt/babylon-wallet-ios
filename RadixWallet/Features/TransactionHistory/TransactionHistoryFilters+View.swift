import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistoryFilters.View
extension TransactionHistoryFilters {
	typealias ViewState = State.Filters

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistoryFilters>

		init(store: StoreOf<TransactionHistoryFilters>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			NavigationStack {
				ScrollView {
					WithViewStore(store, observe: \.filters, send: { .view($0) }) { viewStore in
						VStack(spacing: .medium1) {
							FlowLayout(spacing: .small2) {
								ItemFilterPickerView(filters: viewStore.transferTypes) { id in
									store.send(.view(.filterTapped(id)))
								}
							}
							.padding(.bottom, .small3)

							Divider()

							if viewStore.showAssetsSection {
								Section(L10n.TransactionHistory.Filters.assetTypeLabel) {
									SubSection(
										L10n.TransactionHistory.Filters.tokensLabel,
										filters: viewStore.fungibles,
										labels: tokenLabels,
										store: store
									)

									if !viewStore.nonFungibles.isEmpty {
										Divider()

										SubSection(
											L10n.TransactionHistory.Filters.assetTypeNFTsLabel,
											filters: viewStore.nonFungibles,
											labels: nftLabels,
											store: store
										)
									}
								}

								Divider()
							}

							Section(L10n.TransactionHistory.Filters.transactionTypeLabel) {
								SubSection(filters: viewStore.transactionTypes, store: store)
							}

							Spacer(minLength: 0)
						}
						.padding(.horizontal, .medium1)
					}
				}
				.background(.primaryBackground)
				.footer {
					Button(L10n.TransactionHistory.Filters.showResultsButton) {
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
						Button(L10n.TransactionHistory.Filters.clearAll) {
							store.send(.view(.clearAllTapped))
						}
						.buttonStyle(.blueText)
					}
				}
				.radixToolbar(title: L10n.TransactionHistory.Filters.title, alwaysVisible: false)
			}
		}

		private var tokenLabels: SubSection.CollapseLabels {
			.init(showAll: L10n.TransactionHistory.Filters.tokenShowAll, showLess: L10n.TransactionHistory.Filters.tokenShowLess)
		}

		private var nftLabels: SubSection.CollapseLabels {
			.init(
				showAll: L10n.TransactionHistory.Filters.nftShowAll,
				showLess: L10n.TransactionHistory.Filters.nftShowLess
			)
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
				VStack(spacing: .medium3) {
					Button {
						withAnimation(.default) {
							expanded.toggle()
						}
					} label: {
						HStack(spacing: .zero) {
							Text(name)
								.textStyle(.body1Header)
								.foregroundStyle(.primaryText)

							Spacer()

							Image(expanded ? .chevronUp : .chevronDown)
						}
					}

					if expanded {
						content
					}
				}
				.clipped()
			}
		}

		struct SubSection: SwiftUI.View {
			struct CollapseLabels: Equatable {
				let showAll: String
				let showLess: String
			}

			@SwiftUI.State private var rowHeight: CGFloat = .zero
			@SwiftUI.State private var totalHeight: CGFloat = .zero
			@SwiftUI.State private var isCollapsed: Bool = true

			let heading: String?
			let filters: IdentifiedArrayOf<State.Filter>
			let labels: CollapseLabels?
			let store: StoreOf<TransactionHistoryFilters>

			private var collapsedHeight: CGFloat {
				CGFloat(collapsedRowLimit) * rowHeight + // height of each row
					CGFloat(collapsedRowLimit - 1) * spacing.height + // height of spacing among rows
					2 * clippedPadding // height of padding left on top & bottom to avoid clipping issues
			}

			private let collapsedRowLimit: Int = 3
			private let spacing: CGSize = .init(width: .small3, height: .small2)

			// When clipping the view, the rounded corners elements (which are clipped in a Capsule) next to an edge will look trimmed.
			// Therefore, we leave a minimum padding on each edge to avoid this unwanted effect.
			private let clippedPadding: CGFloat = 1

			init(_ heading: String? = nil, filters: IdentifiedArrayOf<State.Filter>, labels: CollapseLabels? = nil, store: StoreOf<TransactionHistoryFilters>) {
				self.heading = heading
				self.filters = filters
				self.labels = labels
				self.store = store
			}

			var body: some SwiftUI.View {
				if !filters.isEmpty {
					let isCollapsible = labels != nil
					VStack(alignment: .leading, spacing: .medium3) {
						Text(heading)
							.textStyle(.body1HighImportance)
							.foregroundStyle(.secondaryText)

						FlowLayout(spacing: spacing) {
							ItemFilterPickerView(filters: filters) { id in
								store.send(.view(.filterTapped(id)))
							}
						}
						.measureSize(flowLayoutID)
						.overlay {
							DummyFilter()
								.measureSize(flowDummyID)
						}
						.padding(clippedPadding)
						.frame(maxHeight: isCollapsible && isCollapsed ? collapsedHeight : .infinity, alignment: .top)
						.clipped()
						.onReadSizes(flowDummyID, flowLayoutID) { dummySize, flowSize in
							if isCollapsible {
								rowHeight = dummySize.height
								totalHeight = flowSize.height
							}
						}

						if totalHeight > collapsedHeight, let labels {
							Button(isCollapsed ? "+ \(labels.showAll)" : "- \(labels.showLess)") {
								withAnimation {
									isCollapsed.toggle()
								}
							}
							.buttonStyle(.blueText)
							.frame(maxWidth: .infinity)
						}
					}
					.animation(.default, value: isCollapsed)
				}
			}

			private let flowLayoutID = "FlowLayout"
			private let flowDummyID = "FlowDummy"
		}

		struct DummyFilter: SwiftUI.View {
			var body: some SwiftUI.View {
				Text("DUMMY")
					.textStyle(.body1HighImportance)
					.foregroundStyle(.clear)
					.padding(.vertical, .small2)
			}
		}
	}
}

struct ItemFilterPickerView<ID: Hashable & Sendable>: SwiftUI.View {
	let filters: IdentifiedArrayOf<ItemFilter<ID>>
	let onAction: (ID) -> Void

	var body: some SwiftUI.View {
		ForEach(filters) { filter in
			ItemFilterView(filter: filter, action: onAction)
		}
	}
}

struct ItemFilter<ID: Hashable & Sendable>: Hashable, Sendable, Identifiable {
	let id: ID
	let icon: ImageResource?
	let label: String
	var isActive: Bool

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct ItemFilterView<ID: Hashable & Sendable>: SwiftUI.View {
	typealias Filter = ItemFilter<ID>

	let filter: Filter
	let action: (ID) -> Void
	var crossAction: ((ID) -> Void)? = nil

	init(
		filter: Filter,
		action: @escaping (ID) -> Void,
		crossAction: ((ID) -> Void)? = nil
	) {
		self.filter = filter
		self.action = action
		self.crossAction = crossAction
	}

	var body: some SwiftUI.View {
		Button {
			action(filter.id)
		} label: {
			HStack(spacing: .small3) {
				if let icon = filter.icon {
					Image(icon)
				}

				Text(filter.label)
					.lineLimit(1)
					.truncationMode(.tail)
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
				Capsule().fill(filter.isActive ? .chipBackground : .primaryBackground)
				Capsule().stroke(filter.isActive ? .clear : .border)
			}
		}
		.overlay(alignment: .trailing) {
			if showCross, let crossAction {
				Button(asset: AssetResource.close) {
					crossAction(filter.id)
				}
				.tint(.iconTertiary)
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
		filter.isActive ? .white : .primaryText
	}
}
