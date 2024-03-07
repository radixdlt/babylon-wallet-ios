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
							SubSection(filters: viewStore.transferTypes, store: store)

							Divider()

							if viewStore.showAssetsSection {
								Section("Type of asset") { // FIXME: Strings
									SubSection("Tokens", filters: viewStore.fungibles, flexible: tokenLabels, store: store)

									Divider()

									SubSection("NFTs", filters: viewStore.nonFungibles, flexible: nftLabels, store: store)
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
			.init(showAll: "Show all tokens", showLess: "Show fewer tokens")
		}

		private var nftLabels: SubSection.FlexibleLabels {
			.init(showAll: "Show all NFTs", showLess: "Show fewer NFTs")
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

			@SwiftUI.State private var showsAll: Bool = false
			let heading: String?
			let filters: IdentifiedArrayOf<State.Filter>
			let flexible: FlexibleLabels?
			let store: StoreOf<TransactionHistoryFilters>

			init(_ heading: String? = nil, filters: IdentifiedArrayOf<State.Filter>, flexible: FlexibleLabels? = nil, store: StoreOf<TransactionHistoryFilters>) {
				self.heading = heading
				self.filters = filters
				self.flexible = flexible
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
							FlowLayout(spacing: .small1) {
								ForEach(filters) { filter in
									TransactionFilterView(filter: filter) { id in
										store.send(.view(.filterTapped(id)))
									}
								}
							}

							Spacer(minLength: 0)
						}

						if let flexible {
							Button(showsAll ? "- \(flexible.showLess)" : "+ \(flexible.showAll)") {
								showsAll.toggle()
							}
							.buttonStyle(.blueText)
							.padding(.top, .medium3)
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
				.padding(.vertical, .small2)
		}
	}
}
