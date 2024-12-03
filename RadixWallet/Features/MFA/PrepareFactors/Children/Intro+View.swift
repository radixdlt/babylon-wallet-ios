import SwiftUI

// MARK: - Intro.View
extension PrepareFactors.Intro {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.Intro>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .large2) {
					Image(.securityFactors) // TODO: replace

					Text("Let’s Prepare your Factors")
						.textStyle(.sheetTitle)

					VStack(spacing: .medium3) {
						Text(markdown: "You need at least **2 factors** to build a Security Shield. 1 of your factors must be a hardware device.", emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)

						Text("A future wallet update will enable Shields without needing a hardware device.")
					}
					.textStyle(.body1Regular)
					.padding(.horizontal, .medium3)

					InfoButton(.accounts, label: "How your Security Shield is built") // TODO: Replace

					Spacer()
				}
				.foregroundStyle(.app.gray1)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)
				.footer {
					Button("Start") {
						store.send(.view(.startButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}
