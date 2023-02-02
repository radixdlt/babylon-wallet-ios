import FeaturePrelude

// MARK: - LoginRequest.View
public extension LoginRequest {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<LoginRequest>

		public init(store: StoreOf<LoginRequest>) {
			self.store = store
		}
	}
}

public extension LoginRequest.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .zero) {
					NavigationBar(
						leadingItem: CloseButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					Spacer()
						.frame(height: .small2)

					ScrollView {
						VStack {
							VStack(spacing: .medium2) {
								dappImage
								// TODO: login / new login
								Text(title(with: viewStore))
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								subtitle(
									dappName: viewStore.dappName,
									message: subtitleText(with: viewStore)
								)
								.textStyle(.secondaryHeader)
								.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium1)

							// TODO: localize
							Text("Choose a Persona")
								.foregroundColor(.app.gray1)
								.textStyle(.body1Header)
								.padding(.bottom, .medium2)

							ForEachStore(
								store.scope(
									state: \.personas,
									action: { .child(.persona(id: $0, action: $1)) }
								),
								content: { PersonaRow.View(store: $0) }
							)

							Spacer()
								.frame(height: .medium1)

							Button(L10n.Personas.createNewPersonaButtonTitle) {
								viewStore.send(.createNewPersonaButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(
								shouldExpand: false
							))

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}

					// TODO: localize
					ConfirmationFooter(
						title: "Continue",
						isEnabled: true,
						action: {}
					)
				}
			}
		}
	}
}

// MARK: - LoginRequest.View.LoginRequestViewStore
private extension LoginRequest.View {
	typealias LoginRequestViewStore = ComposableArchitecture.ViewStore<LoginRequest.View.ViewState, LoginRequest.Action.ViewAction>
}

// MARK: - Private Computed Properties
private extension LoginRequest.View {
	var dappImage: some View {
		// TODO: use placeholder only when image is unavailable
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	func title(with viewStore: LoginRequestViewStore) -> String {
		viewStore.isKnownDapp ? "Login Request" : "New Login Request"
	}

	func subtitle(dappName: String, message: String) -> some View {
		var component1 = AttributedString(dappName)
		component1.foregroundColor = .app.gray1

		var component2 = AttributedString(message)
		component2.foregroundColor = .app.gray2

		return Text(component1 + component2)
	}

	func subtitleText(with viewStore: LoginRequestViewStore) -> String {
		// TODO: localize
		if viewStore.isKnownDapp {
			return " is requesting you login with a Persona."
		} else {
			return " is requesting you login for the first time with a Persona."
		}
	}
}

// MARK: - LoginRequest.View.ViewState
extension LoginRequest.View {
	struct ViewState: Equatable {
		let dappName: String
		let isKnownDapp: Bool

		init(state: LoginRequest.State) {
			dappName = state.dappMetadata.name
			isKnownDapp = state.isKnownDapp
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - LoginRequest_Preview
struct LoginRequest_Preview: PreviewProvider {
	static var previews: some View {
		LoginRequest.View(
			store: .init(
				initialState: .previewValue,
				reducer: LoginRequest()
			)
		)
	}
}
#endif
