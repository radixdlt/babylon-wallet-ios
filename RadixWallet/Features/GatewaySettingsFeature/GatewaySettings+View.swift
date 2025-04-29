import ComposableArchitecture
import SwiftUI

// MARK: - GatewaySettings.View
extension GatewaySettings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<GatewaySettings>

		init(store: StoreOf<GatewaySettings>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					coreView()
						.padding(.bottom, .medium1)
						.radixToolbar(title: L10n.Gateways.title)
				}
				.background(Color.secondaryBackground)
				.task { @MainActor in await viewStore.send(.view(.task)).finish() }
				.destinations(with: store)
			}
		}

		private func coreView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				subtitle
					.padding(.top, .medium3)
					.padding(.horizontal, .medium3)
					.padding(.bottom, .large2)

				InfoButton(.gateways, label: L10n.InfoLink.Title.gateways)
					.padding(.horizontal, .medium3)
					.padding(.bottom, .large2)

				GatewayList.View(store: store.gatewayList)

				Button(L10n.Gateways.addNewGatewayButtonTitle) {
					store.send(.view(.addGatewayButtonTapped))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.top, .large1)
			}
		}

		private var subtitle: some SwiftUI.View {
			Text(L10n.Gateways.subtitle)
				.foregroundColor(Color.secondaryText)
				.textStyle(.body1HighImportance)
		}
	}
}

private extension StoreOf<GatewaySettings> {
	var destination: PresentationStoreOf<GatewaySettings.Destination> {
		func scopeState(state: State) -> PresentationState<GatewaySettings.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var gatewayList: StoreOf<GatewayList> {
		scope(state: \.gatewayList, action: \.child.gatewayList)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<GatewaySettings>) -> some View {
		let destinationStore = store.destination
		return removeGateway(with: destinationStore)
			.addNewGateway(with: destinationStore)
			.createAccount(with: destinationStore)
	}

	private func removeGateway(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.removeGateway, action: \.removeGateway))
	}

	private func addNewGateway(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewGateway, action: \.addNewGateway)) {
			AddNewGateway.View(store: $0)
		}
	}

	private func createAccount(with destinationStore: PresentationStoreOf<GatewaySettings.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.createAccount, action: \.createAccount)) {
			CreateAccountCoordinator.View(store: $0)
		}
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
	static let previewValue = Self(
		gatewayList: .previewValue
	)
}
#endif
