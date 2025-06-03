import ComposableArchitecture
import SwiftUI

// MARK: - P2PLinks.View
extension P2PLinksFeature {
	struct ViewState: Equatable {
		let linkRows: IdentifiedArrayOf<P2PLink>

		init(state: P2PLinksFeature.State) {
			linkRows = state.links
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<P2PLinksFeature>

		init(store: StoreOf<P2PLinksFeature>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .medium3) {
						Text(L10n.LinkedConnectors.subtitle)
							.textStyle(.body1Header)
							.foregroundStyle(.secondaryText)
							.padding(.horizontal, .medium3)

						VStack(spacing: .zero) {
							ForEach(viewStore.linkRows) { link in
								PlainListRow(title: link.displayName) {
									HStack(spacing: .medium3) {
										Button(asset: AssetResource.create) {
											viewStore.send(.editButtonTapped(link))
										}
										Button(asset: AssetResource.delete) {
											viewStore.send(.removeButtonTapped(link))
										}
									}
								}
								.withSeparator(horizontalPadding: link == viewStore.linkRows.last ? .zero : .medium3)
							}
						}
						.background(.primaryBackground)

						Button(L10n.LinkedConnectors.linkNewConnector) {
							viewStore.send(.addNewConnectionButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(
							shouldExpand: true,
							image: .init(asset: AssetResource.qrCodeScanner)
						))
						.padding(.horizontal, .medium2)
						.padding(.vertical, .medium1)
					}
					.padding(.vertical, .medium3)
				}
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.LinkedConnectors.title)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<P2PLinksFeature> {
	var destination: PresentationStoreOf<P2PLinksFeature.Destination> {
		func scopeState(state: State) -> PresentationState<P2PLinksFeature.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<P2PLinksFeature>) -> some View {
		let destinationStore = store.destination
		return newConnection(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
			.updateName(with: destinationStore)
	}

	private func newConnection(with destinationStore: PresentationStoreOf<P2PLinksFeature.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.newConnection, action: \.newConnection)) {
			NewConnection.View(store: $0)
		}
	}

	private func confirmDeletionAlert(with destinationStore: PresentationStoreOf<P2PLinksFeature.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /P2PLinksFeature.Destination.State.removeConnection,
			action: P2PLinksFeature.Destination.Action.removeConnection
		)
	}

	private func updateName(with destinationStore: PresentationStoreOf<P2PLinksFeature.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.updateName, action: \.updateName)) {
			RenameLabel.View(store: $0)
		}
	}
}
