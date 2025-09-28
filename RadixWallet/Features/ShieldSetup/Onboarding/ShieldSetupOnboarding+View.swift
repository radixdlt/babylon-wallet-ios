import SwiftUI

// MARK: - ShieldSetupOnboarding.View
extension ShieldSetupOnboarding {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ShieldSetupOnboarding>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				coreView
					.safeAreaInset(edge: .bottom, spacing: .zero) {
						VStack(spacing: .medium3) {
							positionIndicator
							let title = store.isLastStep ? L10n.ShieldSetupOnboarding.startButtonTitle : L10n.ShieldSetupOnboarding.nextButtonTitle
							Button(title) {
								store.send(.view(.nextButtonTapped))
							}
							.buttonStyle(.primaryRectangular)
						}
						.padding([.horizontal, .bottom], .medium3)
						.padding(.top, .small3)
						.background(.primaryBackground)
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
			.background(.primaryBackground)
		}

		@ViewBuilder
		private var positionIndicator: some SwiftUI.View {
			HStack(spacing: .small3) {
				ForEach(0 ..< store.steps.count, id: \.self) { index in
					let isSelected = store.selectedStepIndex == index
					Capsule()
						.fill(isSelected ? .textButton : .tertiaryBackground)
						.frame(.small2)
				}
			}
		}
	}
}
