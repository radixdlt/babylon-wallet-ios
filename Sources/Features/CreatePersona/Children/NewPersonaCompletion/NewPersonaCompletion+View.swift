import FeaturePrelude

extension NewPersonaCompletion.State {
	var viewState: NewPersonaCompletion.ViewState {
		.init(state: self)
	}
}

extension NewPersonaCompletion {
	public struct ViewState: Equatable {
		let entityName: String
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explaination: String
		let subtitle: String

		init(state: NewPersonaCompletion.State) {
			entityName = L10n.Common.persona

			destinationDisplayText = {
				switch state.navigationButtonCTA {
				case .goHome:
					return L10n.CreateEntity.Completion.destinationHome
				case .goBackToChooseEntities:
					return L10n.CreateEntity.Completion.destinationChoosePersonas
				case .goBackToPersonaList:
					return L10n.CreateEntity.Completion.destinationPersonaList
				case .goBackToGateways:
					return L10n.CreateEntity.Completion.destinationGateways
				}
			}()

			isFirstOnNetwork = state.isFirstOnNetwork

			self.explaination = L10n.CreatePersona.Completion.explanation

			subtitle = state.isFirstOnNetwork ? L10n.CreatePersona.Completion.subtitleFirst : L10n.CreatePersona.Completion.subtitleNotFirst
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewPersonaCompletion>

		public init(store: StoreOf<NewPersonaCompletion>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					Spacer()

					VStack(spacing: .medium1) {
						Text(L10n.CreateEntity.Completion.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						Text(viewStore.explaination)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .small1)

					Spacer()
				}
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
