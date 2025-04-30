import SwiftUI

// MARK: - ChangeMainShield.View
extension ChangeMainShield {
	struct View: SwiftUI.View {
		let store: StoreOf<ChangeMainShield>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
				}
				.footer {
					WithControlRequirements(
						store.selected,
						forAction: { store.send(.view(.confirmButtonTapped($0))) }
					) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.task {
					store.send(.view(.task))
				}
				.withNavigationBar {
					dismiss()
				}
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .large2) {
				Text(L10n.SecurityShields.ChangeMain.title)
					.textStyle(.sheetTitle)
					.padding(.horizontal, .medium3)

				Text(L10n.SecurityShields.ChangeMain.subtitle)
					.textStyle(.body1Regular)
					.padding(.horizontal, .medium3)

				VStack(spacing: .medium3) {
					ForEachStatic(store.shields) { shield in
						card(shield)
					}
				}

				Spacer()
			}
			.foregroundStyle(.primaryText)
			.multilineTextAlignment(.center)
		}

		private func card(_ shield: ShieldForDisplay) -> some SwiftUI.View {
			WithPerceptionTracking {
				ShieldCard(
					shield: shield,
					mode: .selection(isSelected: store.selected == shield)
				)
				.onTapGesture {
					store.send(.view(.selected(shield)))
				}
			}
		}
	}
}
