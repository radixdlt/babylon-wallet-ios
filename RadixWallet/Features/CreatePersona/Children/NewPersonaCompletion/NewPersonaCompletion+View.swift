import ComposableArchitecture
import SwiftUI

extension NewPersonaCompletion.State {
	var viewState: NewPersonaCompletion.ViewState {
		.init(state: self)
	}
}

extension NewPersonaCompletion {
	struct ViewState: Equatable {
		let entityName: String
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explanation: String
		let subtitle: String

		init(state: NewPersonaCompletion.State) {
			self.entityName = state.persona.displayName.rawValue

			switch state.navigationButtonCTA {
			case .goBackToChoosePersonas:
				self.destinationDisplayText = L10n.CreateEntity.Completion.destinationChoosePersonas
			case .goBackToPersonaListInSettings:
				self.destinationDisplayText = L10n.CreateEntity.Completion.destinationPersonaList
			}

			self.isFirstOnNetwork = state.isFirstOnNetwork
			self.explanation = L10n.CreatePersona.Completion.explanation

			self.subtitle = state.isFirstOnNetwork ? L10n.CreatePersona.Completion.subtitleFirst : L10n.CreatePersona.Completion.subtitleNotFirst
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewPersonaCompletion>

		init(store: StoreOf<NewPersonaCompletion>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					Spacer()

					VStack(spacing: .medium1) {
						Text(L10n.CreateEntity.Completion.title)
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)

						Text(viewStore.explanation)
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .small1)

					Spacer()
				}
				.background(.primaryBackground)
				.padding(.medium1)
				.safeAreaInset(edge: .bottom, spacing: 0) {
					Button(L10n.CreateEntity.Completion.goToDestination(viewStore.destinationDisplayText)) {
						viewStore.send(.goToDestination)
					}
					.buttonStyle(.primaryRectangular)
					.padding(.medium1)
				}
			}
		}
	}
}
