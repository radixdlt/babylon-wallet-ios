import FeaturePrelude

extension IntroductionToPersonas {
	public struct ViewState: Equatable {
		let titleText: String
		init(state: IntroductionToPersonas.State) {
			self.titleText = L10n.CreatePersona.Introduction.title
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<IntroductionToPersonas>

		public init(store: StoreOf<IntroductionToPersonas>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: IntroductionToPersonas.ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .large2) {
						introToPersona(with: viewStore)
					}
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.CreatePersona.Introduction.continue) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.onAppear { viewStore.send(.appeared) }
				.sheet(
					store: store.scope(
						state: \.$infoPanel,
						action: { .child(.infoPanel($0)) }
					),
					content: { SlideUpPanel.View(store: $0) }
				)
			}
		}

		@ViewBuilder
		private func introToPersona(with viewStore: ViewStoreOf<IntroductionToPersonas>) -> some SwiftUI.View {
			// PLACEHOLDER until we get the correct icon.
			Color.app.gray4
				.frame(width: 200, height: 200)
				.cornerRadius(.small2)

			Text(viewStore.titleText)
				.foregroundColor(.app.gray1)
				.textStyle(.sheetTitle)

			//	FIXME: Uncomment and implement
			//	Button(L10n.CreatePersona.Introduction.learnAboutPersonas) {
			//		viewStore.send(.showTutorial)
			//	}
			//	.buttonStyle(.info)

			Text(L10n.CreatePersona.Introduction.subtitle1)
				.font(.app.body1Regular)
				.foregroundColor(.app.gray1)

			Text(L10n.CreatePersona.Introduction.subtitle2)
				.font(.app.body1Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - IntroductionToEntity_Preview
// struct IntroductionToEntity_Preview: PreviewProvider {
//	static var previews: some View {
//		NavigationStack {
//			IntroductionToEntity<Profile.Network.Persona>.View(
//				store: .init(
//					initialState: .init(),
//					reducer: IntroductionToEntity.init
//				)
//			)
//			#if os(iOS)
//			.toolbar(.visible, for: .navigationBar)
//			#endif
//		}
//	}
// }
// #endif
