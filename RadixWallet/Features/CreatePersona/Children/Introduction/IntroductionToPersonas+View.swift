import SwiftUI

// MARK: - IntroductionToPersonas.View
extension IntroductionToPersonas {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<IntroductionToPersonas>

		public init(store: StoreOf<IntroductionToPersonas>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Image(.persona)
							.resizable()
							.frame(.veryHuge)

						Text(L10n.CreatePersona.Introduction.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						InfoButton(.personas, label: L10n.CreatePersona.Introduction.learnAboutPersonas)

						Text(L10n.CreatePersona.Introduction.subtitle1)
							.font(.app.body1Regular)
							.foregroundColor(.app.gray1)

						Text(L10n.CreatePersona.Introduction.subtitle2)
							.font(.app.body1Regular)
							.foregroundColor(.app.gray1)
					}
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large2)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.CreatePersona.Introduction.continue) {
						store.send(.view(.continueButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}
