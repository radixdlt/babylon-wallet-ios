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
								Text("New Login Request")
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								// TODO: dappName + message
								subtitle(
									dappName: "Collabo.Fi",
									message: " is requesting you login for the first time with a Persona."
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

// MARK: - Private Computed Properties
private extension LoginRequest.View {
	var dappImage: some View {
		// TODO: use placeholder only when image is unavailable
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	func subtitle(dappName: String, message: String) -> some View {
		var component1 = AttributedString(dappName)
		component1.foregroundColor = .app.gray1

		var component2 = AttributedString(message)
		component2.foregroundColor = .app.gray2

		return Text(component1 + component2)
	}
}

// MARK: - LoginRequest.View.ViewState
extension LoginRequest.View {
	struct ViewState: Equatable {
		init(state: LoginRequest.State) {
			// TODO: implement
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
