import ComposableArchitecture
import SwiftUI

// MARK: - SecurityStructureConfigurationList.View
extension SecurityStructureConfigurationList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationList>

		public init(store: StoreOf<SecurityStructureConfigurationList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					ScrollView {
						Text("Security Structure Configs") // FIXME: future strings
							.sectionHeading
							.flushedLeft
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Separator()
							.padding(.bottom, .small2)

						list(store: store)
					}

					Button("New Config") { // FIXME: FIXME: future strings
						viewStore.send(.createNewStructure)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
				.navigationTitle("Multifactor Setups") // FIXME: FIXME: future strings
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

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - SecurityStructureConfigurationList_Preview
struct SecurityStructureConfigurationList_Preview: PreviewProvider {
	static var previews: some View {
		SecurityStructureConfigurationList.View(
			store: .init(
				initialState: .previewValue,
				reducer: SecurityStructureConfigurationList.init
			)
		)
	}
}

extension SecurityStructureConfigurationList.State {
	public static let previewValue = Self()
}
#endif
