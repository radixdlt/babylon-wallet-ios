import SwiftUI

// MARK: - SelectFactorSourceKind.View
extension AddFactorSource.SelectKind {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.SelectKind>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						VStack(spacing: .small3) {
							Text("Add Security Factor")
								.textStyle(.sheetTitle)

							Text(markdown: "Choose the Security Factor kind you want to add.", emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
								.textStyle(.body1Regular)
								.lineSpacing(.zero)
						}
						.foregroundStyle(.primaryText)
						.multilineTextAlignment(.center)

						Selection(
							$store.selectedKind.sending(\.view.didSelectKind),
							from: store.kinds
						) { item in
							FactorSourceCard(
								kind: .genericDescription(item.value),
								mode: .selection(type: .radioButton, selectionEnabled: true, isSelected: item.isSelected),
								messages: []
							)
							.onTapGesture(perform: item.action)
						}
					}
					.padding(.horizontal, .medium3)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						store.selectedKind,
						forAction: { store.send(.view(.continueButtonTapped($0))) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.background(.secondaryBackground)
			}
		}
	}
}
