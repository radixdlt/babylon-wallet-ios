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

						Text(L10n.DAppRequest.Completion.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.padding([.top, .horizontal], .medium3)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding([.top, .horizontal], .medium3)

						if let intentHash = viewStore.intentHash {
							AddressView(.transaction(intentHash), imageColor: .app.gray2)
								.foregroundColor(.app.blue1)
								.textStyle(.body1Header)
								.padding(.top, .small2)
						}

						Spacer()

						if viewStore.showSwitchBackToBrowserMessage {
							Text(L10n.MobileConnect.interactionSuccess)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.vertical, .medium1)
								.frame(maxWidth: .infinity)
								.background(.app.gray5)
						}
					}
					.frame(maxWidth: .infinity)
				}
			}
			.presentationDragIndicator(.visible)
			.presentationDetents([.height(height)])
			.presentationBackground(.blur)
		}
	}
}

private extension DappInteractionCompletion.State {
	var subtitle: String {
		switch kind {
		case .personaData, .transaction:
			L10n.DAppRequest.Completion.subtitle(dappMetadata.name)
		case .preAuthorization:
			L10n.DAppRequest.Completion.subtitlePreAuthorization
		}
	}

	var intentHash: TransactionIntentHash? {
		switch kind {
		case .personaData:
			nil
		case let .transaction(intentHash), let .preAuthorization(intentHash):
			intentHash
		}
	}

	var showSwitchBackToBrowserMessage: Bool {
		p2pRoute.isDeepLink
	}
}
