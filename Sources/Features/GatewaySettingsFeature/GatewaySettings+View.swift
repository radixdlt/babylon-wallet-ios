import CreateEntityFeature
import FeaturePrelude

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
						.navigationTitle(L10n.GatewaySettings.title)
						.task { @MainActor in await ViewStore(store.stateless).send(.view(.task)).finish() }
						.alert(
							store: store.scope(
								state: \.$removeGatewayAlert,
								action: { .view(.removeGateway($0)) }
							)
						)
						.sheet(
							store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
							state: /Destinations.State.addNewGateway,
							action: Destinations.Action.addNewGateway,
							content: {
								AddNewGateway.View(store: $0)
									.presentationDetents([.medium])
									.presentationDragIndicator(.visible)
								#if os(iOS)
									.presentationBackground(.blur)
								#endif
							}
						)
						.sheet(
							store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
							state: /Destinations.State.createAccount,
							action: Destinations.Action.createAccount,
							content: { CreateAccountCoordinator.View(store: $0) }
						)
						.sheet(
							store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
							state: /Destinations.State.explanationPanel,
							action: Destinations.Action.explanationPanel,
							content: {
								ExplanationPanel.View(store: $0)
									.presentationDetents([.medium])
									.presentationDragIndicator(.visible)
								#if os(iOS)
									.presentationBackground(.blur)
								#endif
							}
						)
				}
			}
		}

		private func coreView(with viewStore: ViewStoreOf<GatewaySettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				VStack(spacing: .small2) {
					subtitle

					whatIsAGatewayButton(with: viewStore)
						.flushedLeft
						.padding(.vertical, .medium2)

					Separator()
				}
				.padding([.leading, .trailing, .top], .medium3)

				gatewayList

				Spacer()
					.frame(height: .large1)

				Button(L10n.GatewaySettings.addNewGatewayButtonTitle) {
					viewStore.send(.addGatewayButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium1)
			}
		}

		private var subtitle: some SwiftUI.View {
			Text(L10n.GatewaySettings.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1HighImportance)
				.flushedLeft
		}

		private var gatewayList: some SwiftUI.View {
			GatewayList.View(
				store: store.scope(
					state: \.gatewayList,
					action: { .child(.gatewayList($0)) }
				)
			)
		}

		private func whatIsAGatewayButton(with viewStore: ViewStoreOf<GatewaySettings>) -> some SwiftUI.View {
			Button {
				viewStore.send(.popoverButtonTapped)
			} label: {
				HStack {
					Image(asset: AssetResource.info)
					Text(L10n.GatewaySettings.WhatIsAGateway.buttonText)
						.textStyle(.body1StandaloneLink)
				}
				.tint(.app.blue2)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - GatewaySettings_Preview
struct GatewaySettings_Preview: PreviewProvider {
	static var previews: some View {
		GatewaySettings.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatewaySettings()
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
