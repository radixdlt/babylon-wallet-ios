import FeaturePrelude

extension SecurityStructureConfigurationList.State {
	var viewState: SecurityStructureConfigurationList.ViewState {
		.init()
	}
}

// MARK: - SecurityStructureConfigurationList.View
extension SecurityStructureConfigurationList {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

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
						Text("Security Structure Configs")
							.sectionHeading
							.flushedLeft
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Separator()
							.padding(.bottom, .small2)

						SecurityStructureConfigListCoreView(store: store)
					}

					// FIXME: String
					Button("New Config") {
						viewStore.send(.createNewStructure)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.navigationTitle("Mult-Factor Setups")
			}
		}
	}
}

// MARK: - SecurityStructureConfigListCoreView
public struct SecurityStructureConfigListCoreView: View {
	private let store: StoreOf<SecurityStructureConfigurationList>

	public init(store: StoreOf<SecurityStructureConfigurationList>) {
		self.store = store
	}

	public var body: some View {
		VStack(spacing: .medium3) {
			ForEachStore(
				store.scope(
					state: \.configs,
					action: { .child(.config(id: $0, action: $1)) }
				)
			) {
				EditSecurityStructureConfiguration.View(store: $0)
					.padding(.horizontal, .medium3)
			}
		}
		.task {
			ViewStore(store).send(.view(.task))
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SecurityStructureConfigurationList_Preview
struct SecurityStructureConfigurationList_Preview: PreviewProvider {
	static var previews: some View {
		SecurityStructureConfigurationList.View(
			store: .init(
				initialState: .previewValue,
				reducer: SecurityStructureConfigurationList()
			)
		)
	}
}

extension SecurityStructureConfigurationList.State {
	public static let previewValue = Self()
}
#endif
