import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - IncomingConnectionRequestFromDappReview.View
public extension IncomingConnectionRequestFromDappReview {
	struct View: SwiftUI.View {
		private let store: StoreOf<IncomingConnectionRequestFromDappReview>
		@ObservedObject private var viewStore: ViewStoreOf<IncomingConnectionRequestFromDappReview>

		public init(
			store: StoreOf<IncomingConnectionRequestFromDappReview>
		) {
			self.store = store
			viewStore = ViewStore(self.store)
		}
	}
}

public extension IncomingConnectionRequestFromDappReview.View {
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
					Text(L10n.Persona.ConnectionRequest.wantsToConnect(viewStore.incomingConnectionRequestFromDapp.name))
						.textStyle(.secondaryHeader)

					Text(L10n.Persona.ConnectionRequest.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body1Regular)
				}
				.multilineTextAlignment(.center)

				Spacer(minLength: 60)

				PermissionsView(permissions: viewStore.incomingConnectionRequestFromDapp.permissions)
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

// MARK: - IncomingConnectionRequestFromDappReview.View.ViewAction
extension IncomingConnectionRequestFromDappReview.View {
	enum ViewAction: Equatable {}
}

extension IncomingConnectionRequestFromDappReview.Action {
	init(action: IncomingConnectionRequestFromDappReview.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.View.ViewState
extension IncomingConnectionRequestFromDappReview.View {
	struct ViewState: Equatable {
		init(state _: IncomingConnectionRequestFromDappReview.State) {
			// TODO: implement
		}
	}
}

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
