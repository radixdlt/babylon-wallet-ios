import ComposableArchitecture
import SwiftUI
extension GatewaySettings.State {
	var viewState: GatewaySettings.ViewState { .init() }
}

// MARK: - GatewaySettings.View
extension GatewaySettings {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GatewaySettings>

		public init(store: StoreOf<GatewaySettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					coreView(with: viewStore)
						.padding(.bottom, .medium1)
						.navigationTitle(L10n.Gateways.title)
						.task { @MainActor in await store.send(.view(.task)).finish() }
						.destinations(with: store)
				}
			}
		}

		private func coreView(with viewStore: ViewStoreOf<GatewaySettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .small2) {
					subtitle

					//	FIXME: Uncomment and implement
					//	Button(L10n.Gateways.whatIsAGateway) {
					//		viewStore.send(.popoverButtonTapped)
					//	}
					//	.buttonStyle(.info)
					//	.padding(.vertical, .medium2)

					Separator()
				}
				.padding([.leading, .trailing, .top], .medium3)

				gatewayList

				Spacer()
					.frame(height: .large1)

				Button(L10n.Gateways.addNewGatewayButtonTitle) {
					viewStore.send(.addGatewayButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium1)
			}
		}

		private var subtitle: some SwiftUI.View {
			Text(L10n.Gateways.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1HighImportance)
		}

		private var gatewayList: some SwiftUI.View {
			GatewayList.View(
				store: store.scope(
					state: \.gatewayList,
					action: { .child(.gatewayList($0)) }
				)
			)
		}
	}
}

private extension StoreOf<GatewaySettings> {
	var destination: PresentationStoreOf<GatewaySettings.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<GatewaySettings>) -> some View {
		let destinationStore = store.destination
		return removeGateway(with: destinationStore)
			.addNewGateway(with: destinationStore)
			.createAccount(with: destinationStore)
			.slideUpPanel(with: destinationStore)
	}

	private func removeGateway(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /GatewaySettings.Destination.State.removeGateway,
			action: GatewaySettings.Destination.Action.removeGateway
		)
	}

	private func addNewGateway(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /GatewaySettings.Destination.State.addNewGateway,
			action: GatewaySettings.Destination.Action.addNewGateway,
			content: { store in
				WithNavigationBar {
					store.send(.view(.closeButtonTapped))
				} content: {
					AddNewGateway.View(store: store)
				}
			}
		)
	}

	private func createAccount(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /GatewaySettings.Destination.State.createAccount,
			action: GatewaySettings.Destination.Action.createAccount,
			content: { CreateAccountCoordinator.View(store: $0) }
		)
	}

	private func slideUpPanel(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /GatewaySettings.Destination.State.slideUpPanel,
			action: GatewaySettings.Destination.Action.slideUpPanel,
			content: { SlideUpPanel.View(store: $0) }
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - GatewaySettings_Preview
struct GatewaySettings_Preview: PreviewProvider {
	static var previews: some View {
		GatewaySettings.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatewaySettings.init
			)
		)
	}
}

extension GatewaySettings.State {
	public static let previewValue = Self(
		gatewayList: .previewValue
	)
}
#endif
