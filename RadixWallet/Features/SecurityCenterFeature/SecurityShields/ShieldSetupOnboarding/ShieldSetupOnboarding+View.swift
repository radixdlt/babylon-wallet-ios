import SwiftUI

// MARK: - ShieldSetupOnboarding.View
extension ShieldSetupOnboarding {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ShieldSetupOnboarding>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				coreView
					.safeAreaInset(edge: .bottom, spacing: 0) {
						VStack(spacing: 0) {
							positionIndicator
								.padding(.vertical, .small1)

							let title = store.isLastStep ? L10n.ShieldsSetupOnboarding.startButtonTitle : L10n.ShieldsSetupOnboarding.nextButtonTitle
							Button(title) {
								store.send(.view(.nextButtonTapped))
							}
							.buttonStyle(.primaryRectangular)
							.padding(.medium3)
						}
						.background(Color.app.background)
					}
					.withNavigationBar {
						dismiss()
					}
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			TabView(selection: $store.selectedStepIndex.sending(\.view.selectedStepIndexChanged)) {
				ForEach(Array(store.steps.enumerated()), id: \.element) { index, step in
					ShieldSetupOnboardingStepView(step: step)
						.tag(index)
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
			.animation(.easeInOut, value: store.selectedStepIndex)
			.transition(.slide)
		}

		@ViewBuilder
		private var positionIndicator: some SwiftUI.View {
			HStack(spacing: .small3) {
				ForEach(0 ..< store.steps.count, id: \.self) { index in
					let isSelected = store.selectedStepIndex == index
					Capsule()
						.fill(isSelected ? .app.blue2 : .app.gray4)
						.frame(.small2)
				}
			}
		}
	}
}
