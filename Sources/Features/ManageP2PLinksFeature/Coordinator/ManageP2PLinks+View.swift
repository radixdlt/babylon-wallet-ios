import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PLinks.View
extension ManageP2PLinks {
	public struct ViewState: Equatable {
		public let clients: IdentifiedArrayOf<ManageP2PLink.State>

		init(state: ManageP2PLinks.State) {
			clients = state.links
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageP2PLinks>

		public init(store: StoreOf<ManageP2PLinks>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					Text(L10n.ManageP2PLinks.p2PConnectionsSubtitle)
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
								ManageP2PLink.View(store: $0)
									.padding(.medium3)

								Separator()
							}
						)
					}
					Button(L10n.ManageP2PLinks.newConnectionButtonTitle) {
						viewStore.send(.addNewConnectionButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(
						shouldExpand: true,
						image: .init(asset: AssetResource.qrCodeScanner)
					))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.navigationTitle(L10n.ManageP2PLinks.p2PConnectionsTitle)
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ManageP2PLinks.Destinations.State.newConnection,
					action: ManageP2PLinks.Destinations.Action.newConnection,
					content: { NewConnection.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ManageP2PLinks_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			ManageP2PLinks.View(
				store: .init(
					initialState: .previewValue,
					reducer: ManageP2PLinks()
				)
			)
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}
}

extension ManageP2PLinks.State {
	public static let previewValue: Self = .init()
}
#endif
