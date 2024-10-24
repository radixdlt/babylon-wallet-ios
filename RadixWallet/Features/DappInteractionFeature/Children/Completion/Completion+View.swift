import ComposableArchitecture
import SwiftUI

extension DappMetadata {
	var name: String {
		switch self {
		case let .ledger(ledger):
			ledger.name?.rawValue ?? L10n.DAppRequest.Metadata.unknownName
		case .request:
			L10n.DAppRequest.Metadata.unknownName
		case .wallet:
			L10n.DAppRequest.Metadata.wallet
		}
	}
}

// MARK: - Completion.View
extension Completion {
	struct ViewState: Equatable {
		/// `nil` is a valid value for Persona Data requests
		let txID: TransactionIntentHash?
		let title: String
		let subtitle: String
		let showSwitchBackToBrowserMessage: Bool

		init(state: Completion.State) {
			self.txID = state.txID
			self.title = L10n.DAppRequest.Completion.title
			self.subtitle = L10n.DAppRequest.Completion.subtitle(state.dappMetadata.name)
			self.showSwitchBackToBrowserMessage = state.p2pRoute.isDeepLink
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Completion>

		@ScaledMetric private var height: CGFloat = 360

		var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init) { viewStore in
				WithNavigationBar {
					store.send(.view(.dismissTapped))
				} content: {
					VStack(spacing: .zero) {
						Spacer()

						Image(asset: AssetResource.successCheckmark)

						Text(viewStore.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.padding([.top, .horizontal], .medium3)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding([.top, .horizontal], .medium3)

						if let txID = viewStore.txID {
							HStack {
								Text(L10n.TransactionReview.SubmitTransaction.txID)
									.foregroundColor(.app.gray1)
								AddressView(.transaction(txID), imageColor: .app.gray2)
									.foregroundColor(.app.blue1)
							}
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

#if DEBUG
import struct SwiftUINavigation.WithState

// MARK: - Completion_Preview
struct Completion_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		WithState(initialValue: false) { $isPresented in
			ZStack {
				Color.red
				Button("Present") { isPresented = true }
			}
			.sheet(isPresented: $isPresented) {
				Completion.View(
					store: .init(
						initialState: .previewValue,
						reducer: Completion.init
					)
				)
			}
			.task {
				try? await Task.sleep(for: .seconds(2))
				isPresented = true
			}
		}
	}
}

extension Completion.State {
	static let previewValue: Self = .init(
		txID: nil,
		dappMetadata: .previewValue,
		p2pRoute: .wallet
	)
}
#endif
