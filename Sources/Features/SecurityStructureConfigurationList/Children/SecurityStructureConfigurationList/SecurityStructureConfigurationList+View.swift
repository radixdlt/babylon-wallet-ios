import FeaturePrelude

extension SecurityStructureConfigurationList.State {
	var viewState: SecurityStructureConfigurationList.ViewState {
		.init(state: self)
	}
}

// MARK: - SecurityStructureConfigurationList.View
extension SecurityStructureConfigurationList {
	public struct ViewState: Equatable {
		var allowSelection: Bool { context != .settings }
		let context: State.Context
		let configurations: IdentifiedArrayOf<SecurityStructureConfigurationReference>
		var configurationsArray: [SecurityStructureConfigurationReference]? { .init(configurations) }
		init(state: State) {
			self.context = state.context
			self.configurations = .init(uncheckedUniqueElements: state.configs.map(\.configReference))
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationList>

		public init(store: StoreOf<SecurityStructureConfigurationList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					ScrollView {
						Text("Security Structure Configs")
							.sectionHeading
							.flushedLeft
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Separator()
							.padding(.bottom, .small2)

						if viewStore.allowSelection {
							Selection(
								viewStore.binding(
									get: \.configurationsArray,
									send: { .selectedConfig($0?.first) }
								),
								from: viewStore.configurations,
								requiring: .exactly(1)
							) { item in
								SecurityStructureConfigurationRowView
								SecurityStructureConfigurationRow.View(
									viewState: .init(factorSource: item.value),
									isSelected: item.isSelected,
									action: item.action
								)
							}
						} else {
							list(store: store)
						}
					}

					// FIXME: Strings
					Button("New Config") {
						viewStore.send(.createNewStructure)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
				// FIXME: Strings
				.navigationTitle("Multifactor Setups")
			}
		}

		func list(store: StoreOf<SecurityStructureConfigurationList>) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEachStore(
					store.scope(
						state: \.configs,
						action: { .child(.config(id: $0, action: $1)) }
					)
				) {
					SecurityStructureConfigurationRow.View(store: $0)
						.padding(.horizontal, .medium3)
				}
			}
		}
	}
}
