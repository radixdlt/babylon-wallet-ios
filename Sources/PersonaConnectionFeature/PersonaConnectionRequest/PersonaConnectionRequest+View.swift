import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - PersonaConnectionRequest.View
public extension PersonaConnectionRequest {
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonaConnectionRequest>
		@ObservedObject private var viewStore: ViewStoreOf<PersonaConnectionRequest>

		public init(
			store: StoreOf<PersonaConnectionRequest>
		) {
			self.store = store
			viewStore = ViewStore(self.store)
		}
	}
}

public extension PersonaConnectionRequest.View {
	var body: some View {
		ScrollView {
			VStack {
				VStack(spacing: 40) {
					Text(L10n.Persona.ConnectionRequest.title)
						.textStyle(.sectionHeader)
						.multilineTextAlignment(.center)

					Image("dapp-placeholder", bundle: .module)
				}

				Spacer(minLength: 40)

				VStack(spacing: 20) {
					Text(L10n.Persona.ConnectionRequest.wantsToConnect(viewStore.dApp.name))
						.textStyle(.secondaryHeader)

					Text(L10n.Persona.ConnectionRequest.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body1Regular)
				}
				.multilineTextAlignment(.center)

				Spacer(minLength: 60)

				PermissionsView(permissions: viewStore.dApp.permissions)
					.padding(.horizontal, 24)

				Spacer()

				PrimaryButton(
					title: L10n.Persona.ConnectionRequest.continueButtonTitle,
					action: { /* TODO: implement */ }
				)
			}
			.padding(.horizontal, 24)
		}
	}
}

// MARK: - PersonaConnectionRequest.View.ViewAction
extension PersonaConnectionRequest.View {
	enum ViewAction: Equatable {}
}

extension PersonaConnectionRequest.Action {
	init(action: PersonaConnectionRequest.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - PersonaConnectionRequest.View.ViewState
extension PersonaConnectionRequest.View {
	struct ViewState: Equatable {
		init(state _: PersonaConnectionRequest.State) {
			// TODO: implement
		}
	}
}

// MARK: - PersonaConnectionRequest_Preview
struct PersonaConnectionRequest_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return PersonaConnectionRequest.View(
			store: .init(
				initialState: .placeholder,
				reducer: PersonaConnectionRequest()
			)
		)
	}
}
