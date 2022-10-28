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
			send: IncomingConnectionRequestFromDappReview.Action.init(action:)
		) { viewStore in
			ForceFullScreen {
				ZStack {
					mainView(with: viewStore)
						.zIndex(0)
				}

				IfLetStore(
					store.scope(
						state: \.chooseAccounts,
						action: IncomingConnectionRequestFromDappReview.Action.chooseAccounts
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
				.padding(24)

			ScrollView {
				VStack {
					VStack(spacing: 40) {
						Text(L10n.DApp.ConnectionRequest.title)
							.textStyle(.sectionHeader)
							.multilineTextAlignment(.center)

						Image("dapp-placeholder")
					}

					Spacer(minLength: 40)

					VStack(spacing: 20) {
						Text(L10n.DApp.ConnectionRequest.wantsToConnect(viewStore.incomingConnectionRequestFromDapp.displayName))
							.textStyle(.secondaryHeader)

						Text(L10n.DApp.ConnectionRequest.subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
					}
					.multilineTextAlignment(.center)

					Spacer(minLength: 60)

					PermissionsView(permissions: viewStore.incomingConnectionRequestFromDapp.permissions)
						.padding(.horizontal, 24)

					Spacer()

					PrimaryButton(
						title: L10n.DApp.ConnectionRequest.continueButtonTitle,
						action: { viewStore.send(.continueButtonTapped) }
					)
				}
				.padding(.horizontal, 24)
			}
		}
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.View.IncomingConnectionViewStore
private extension IncomingConnectionRequestFromDappReview.View {
	typealias IncomingConnectionViewStore = ComposableArchitecture.ViewStore<IncomingConnectionRequestFromDappReview.View.ViewState, IncomingConnectionRequestFromDappReview.View.ViewAction>
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

// MARK: - IncomingConnectionRequestFromDappReview.View.ViewAction
extension IncomingConnectionRequestFromDappReview.View {
	enum ViewAction: Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}
}

extension IncomingConnectionRequestFromDappReview.Action {
	init(action: IncomingConnectionRequestFromDappReview.View.ViewAction) {
		switch action {
		case .dismissButtonTapped:
			self = .internal(.user(.dismissIncomingConnectionRequest))
		case .continueButtonTapped:
			self = .internal(.user(.proceedWithConnectionRequest))
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
