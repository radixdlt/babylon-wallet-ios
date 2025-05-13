import ComposableArchitecture
import SwiftUI

// MARK: - DappInteractionCompletion.View
extension DappInteractionCompletion {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionCompletion>

		@ScaledMetric private var height: CGFloat = 360

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				WithNavigationBar {
					store.send(.view(.dismissTapped))
				} content: {
					VStack(spacing: .zero) {
						Spacer()

						Image(asset: AssetResource.successCheckmark)
							.darkModeTinted()

						Text(L10n.DAppRequest.Completion.title)
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)
							.padding([.top, .horizontal], .medium3)

						Text(L10n.DAppRequest.Completion.subtitle(viewStore.dappMetadata.name))
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding([.top, .horizontal], .medium3)

						if let intentHash = viewStore.intentHash {
							AddressView(.transaction(intentHash), imageColor: .secondaryText)
								.foregroundColor(.textButton)
								.textStyle(.body1Header)
								.padding(.top, .small2)
						}

						Spacer()

						if viewStore.showSwitchBackToBrowserMessage {
							Text(L10n.MobileConnect.interactionSuccess)
								.foregroundColor(.primaryText)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.vertical, .medium1)
								.frame(maxWidth: .infinity)
								.background(.secondaryBackground)
						}
					}
					.frame(maxWidth: .infinity)
					.background(.primaryBackground)
				}
			}
			.presentationDragIndicator(.visible)
			.presentationDetents([.height(height)])
			.presentationBackground(.blur)
		}
	}
}

private extension DappInteractionCompletion.State {
	var intentHash: TransactionIntentHash? {
		switch kind {
		case .personaData:
			nil
		case let .transaction(intentHash):
			intentHash
		}
	}

	var showSwitchBackToBrowserMessage: Bool {
		p2pRoute.isDeepLink
	}
}
