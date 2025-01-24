import SwiftUI

// MARK: - ChangeMainShield.View
extension ChangeMainShield {
	struct View: SwiftUI.View {
		let store: StoreOf<ChangeMainShield>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Text("Change Default Shield")
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text("Choose which Security Shield will be pre-selected when you want to use one for an Account or Persona.")
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium3)

						VStack(spacing: .medium3) {
							ForEachStatic(store.shields) { shield in
								card(shield)
							}
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
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
