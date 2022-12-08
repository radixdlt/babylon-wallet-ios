import Common
import ComposableArchitecture
import DesignSystem
import SharedModels
import SwiftUI

// MARK: - DappConnectionRequest.View
public extension DappConnectionRequest {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DappConnectionRequest>

		public init(store: StoreOf<DappConnectionRequest>) {
			self.store = store
		}
	}
}

public extension DappConnectionRequest.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
                        ForceFullScreen {
                                VStack {
                                        NavigationBar(
                                                leadingItem: CloseButton {
                                                        viewStore.send(.dismissButtonTapped)
                                                }
                                        )
                                        .foregroundColor(.app.gray1)
                                        .padding([.horizontal, .top], .medium3)

                                        ScrollView {
                                                VStack {
                                                        VStack(spacing: .large1) {
                                                                Text(L10n.DApp.ConnectionRequest.title)
                                                                        .foregroundColor(.app.gray1)
                                                                        .textStyle(.sectionHeader)
                                                                        .multilineTextAlignment(.center)

                                                                Image(asset: AssetResource.dappPlaceholder)
                                                        }

                                                        Spacer(minLength: .large1)

                                                        VStack(spacing: .medium2) {
                                                                Text(L10n.DApp.ConnectionRequest.wantsToConnect(viewStore.requestFromDapp.metadata.dAppId))
                                                                        .foregroundColor(.app.gray1)
                                                                        .textStyle(.secondaryHeader)

                                                                Text(L10n.DApp.ConnectionRequest.subtitle)
                                                                        .foregroundColor(.app.gray1)
                                                                        .textStyle(.body1Regular)
                                                        }
                                                        .multilineTextAlignment(.center)

                                                        Spacer(minLength: .large1 * 1.5)

                                                        Spacer()

                                                        Button(L10n.DApp.ConnectionRequest.continueButtonTitle) {
                                                                viewStore.send(.continueButtonTapped)
                                                        }
                                                        .buttonStyle(.primaryRectangular)
                                                }
                                                .padding(.horizontal, .medium1)
                                        }
                                }
                        }
                }
	}
}

// MARK: - DappConnectionRequest.View.ViewStore
private extension DappConnectionRequest.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, DappConnectionRequest.Action.ViewAction>
}

// MARK: - DappConnectionRequest.View.ViewState
extension DappConnectionRequest.View {
	struct ViewState: Equatable {
		var requestFromDapp: P2P.FromDapp.Request
		init(state: DappConnectionRequest.State) {
			requestFromDapp = state.request.parentRequest.requestFromDapp
		}
	}
}

// #if DEBUG
//
//// MARK: - IncomingConnectionRequestFromDappReview_Preview
// struct IncomingConnectionRequestFromDappReview_Preview: PreviewProvider {
//	static var previews: some View {
//		registerFonts()
//
//		return DappConnectionRequest.View(
//			store: .init(
//				initialState: .placeholder,
//				reducer: DappConnectionRequest()
//			)
//		)
//	}
// }
// #endif // DEBUG
