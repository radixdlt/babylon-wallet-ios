import ComposableArchitecture
import SwiftUI

// MARK: - P2PLinks.View
extension P2PLinksFeature {
	public struct ViewState: Equatable {
		public let linkRows: IdentifiedArrayOf<P2PLinkRow.State>

		init(state: P2PLinksFeature.State) {
			linkRows = state.links
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<P2PLinksFeature>

		public init(store: StoreOf<P2PLinksFeature>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					Text(L10n.LinkedConnectors.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body1HighImportance)
						.flushedLeft
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .small2)

					Separator()

					VStack(alignment: .leading) {
						ForEachStore(
							store.scope(
								state: \.links,
								action: { .child(.connection(id: $0, action: $1)) }
							),
							content: {
								P2PLinkRow.View(store: $0)
									.padding(.medium3)

								Separator()
							}
						)
					}
					Button(L10n.LinkedConnectors.linkNewConnector) {
						viewStore.send(.addNewConnectionButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(
						shouldExpand: true,
						image: .init(asset: AssetResource.qrCodeScanner)
					))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.navigationTitle(L10n.LinkedConnectors.title)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<P2PLinksFeature> {
	var destination: PresentationStoreOf<P2PLinksFeature.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<P2PLinksFeature>) -> some View {
		let destinationStore = store.destination
		return newConnection(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
	}

	private func newConnection(with destinationStore: PresentationStoreOf<P2PLinksFeature.Destination_>) -> some View {
		sheet(
			store: destinationStore,
			state: /P2PLinksFeature.Destination_.State.newConnection,
			action: P2PLinksFeature.Destination_.Action.newConnection,
			content: { NewConnection.View(store: $0) }
		)
	}

	private func confirmDeletionAlert(with destinationStore: PresentationStoreOf<P2PLinksFeature.Destination_>) -> some View {
		alert(
			store: destinationStore,
			state: /P2PLinksFeature.Destination_.State.removeConnection,
			action: P2PLinksFeature.Destination_.Action.removeConnection
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
struct P2PLinksFeature_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			P2PLinksFeature.View(
				store: .init(
					initialState: .previewValue,
					reducer: P2PLinksFeature.init
				)
			)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

extension P2PLinksFeature.State {
	public static let previewValue: Self = .init()
}
#endif
