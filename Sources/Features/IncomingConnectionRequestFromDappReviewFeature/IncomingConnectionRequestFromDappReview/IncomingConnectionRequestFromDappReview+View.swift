import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - IncomingConnectionRequestFromDappReview.View
public extension IncomingConnectionRequestFromDappReview {
	struct View: SwiftUI.View {
		private let store: StoreOf<IncomingConnectionRequestFromDappReview>

		public init(store: StoreOf<IncomingConnectionRequestFromDappReview>) {
			self.store = store
		}
	}
}

public extension IncomingConnectionRequestFromDappReview.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					mainView(with: viewStore)
						.zIndex(0)
				}

				IfLetStore(
					store.scope(
						state: \.chooseAccounts,
						action: { .child(.chooseAccounts($0)) }
					),
					then: ChooseAccounts.View.init(store:)
				)
				.zIndex(1)
			}
		}
	}
}

private extension IncomingConnectionRequestFromDappReview.View {
	func mainView(with viewStore: IncomingConnectionViewStore) -> some View {
		VStack {
			header(with: viewStore)
				.padding(.medium1)

			ScrollView {
				VStack {
					VStack(spacing: .large1) {
						Text(L10n.DApp.ConnectionRequest.title)
							.textStyle(.sectionHeader)
							.multilineTextAlignment(.center)

						Image(asset: Asset.dappPlaceholder)
					}

					Spacer(minLength: .large1)

					VStack(spacing: .medium2) {
						Text(L10n.DApp.ConnectionRequest.wantsToConnect(viewStore.incomingConnectionRequestFromDapp.displayName))
							.textStyle(.secondaryHeader)

						Text(L10n.DApp.ConnectionRequest.subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
					}
					.multilineTextAlignment(.center)

					Spacer(minLength: .large1 * 1.5)

					PermissionsView(permissions: viewStore.incomingConnectionRequestFromDapp.permissions)
						.padding(.horizontal, .medium1)

					Spacer()

					Button(L10n.DApp.ConnectionRequest.continueButtonTitle) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primary)
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.View.IncomingConnectionViewStore
private extension IncomingConnectionRequestFromDappReview.View {
	typealias IncomingConnectionViewStore = ViewStore<IncomingConnectionRequestFromDappReview.View.ViewState, IncomingConnectionRequestFromDappReview.Action.ViewAction>
}

private extension IncomingConnectionRequestFromDappReview.View {
	func header(with viewStore: IncomingConnectionViewStore) -> some View {
		HStack {
			CloseButton {
				viewStore.send(.dismissButtonTapped)
			}
			Spacer()
		}
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.View.ViewState
extension IncomingConnectionRequestFromDappReview.View {
	struct ViewState: Equatable {
		let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp

		init(state: IncomingConnectionRequestFromDappReview.State) {
			incomingConnectionRequestFromDapp = state.incomingConnectionRequestFromDapp
		}
	}
}

#if DEBUG

// MARK: - IncomingConnectionRequestFromDappReview_Preview
struct IncomingConnectionRequestFromDappReview_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return IncomingConnectionRequestFromDappReview.View(
			store: .init(
				initialState: .placeholder,
				reducer: IncomingConnectionRequestFromDappReview()
			)
		)
	}
}
#endif // DEBUG
