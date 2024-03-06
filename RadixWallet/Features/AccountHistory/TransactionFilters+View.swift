import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistoryFilters.View
extension TransactionFilters {
	public typealias ViewState = State.Filters

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionFilters>

		public init(store: StoreOf<TransactionFilters>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				WithViewStore(store, observe: \.filters, send: { .view($0) }) { viewStore in
					VStack {
						SubSection(filters: viewStore.transferTypes, flexible: false, store: store)

						Section("Type of asset") {
							SubSection("Tokens", filters: viewStore.fungibles, store: store)

							SubSection("NFTs", filters: viewStore.nonFungibles, store: store)
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
			let store: StoreOf<TransactionFilters>

			init(_ heading: String? = nil, filters: IdentifiedArrayOf<State.Filter>, flexible: Bool = true, store: StoreOf<TransactionFilters>) {
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
									FilterView(filter: filter) {
										store.send(.view(.addTapped(filter.id)))
									} removeAction: {
										store.send(.view(.removeTapped(filter.id)))
									}
								}
							}
							.border(.red)

							Spacer(minLength: 0)
						}
					}
				}
			}
		}

		struct FilterView: SwiftUI.View {
			let filter: State.Filter
			let addAction: () -> Void
			let removeAction: () -> Void

			var body: some SwiftUI.View {
				Button(action: addAction) {
					Text(filter.label)
						.foregroundStyle(filter.isActive ? .app.white : .app.gray1)
						.textStyle(.body1HighImportance)
						.padding(.horizontal, .medium3)
						.padding(.vertical, .small2)
				}
				.contentShape(Capsule())
				.disabled(filter.isActive)
				.padding(.trailing, filter.isActive ? .medium1 : 0)
				.background {
					ZStack {
						Capsule().fill(filter.isActive ? .app.gray1 : .app.white)
						Capsule().stroke(filter.isActive ? .clear : .app.gray3)
					}
				}
				.overlay(alignment: .trailing) {
					if filter.isActive {
						Button(asset: AssetResource.close, action: removeAction)
							.tint(.app.gray3)
							.padding(.vertical, -.small3)
							.padding(.trailing, .small2)
							.transition(.scale.combined(with: .opacity))
					}
				}
				.animation(.default.speed(2), value: filter.isActive)
			}

			struct Dummy: SwiftUI.View {
				var body: some SwiftUI.View {
					Text("ABC")
						.textStyle(.body1HighImportance)
						.padding(.vertical, .small2)
				}
			}
		}
	}
}