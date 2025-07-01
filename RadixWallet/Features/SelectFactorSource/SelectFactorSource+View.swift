import SwiftUI

// MARK: - SelectFactorSource.View
extension SelectFactorSource {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<SelectFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium2)
				}
				.footer {
					VStack(spacing: .medium3) {
						Button("Add a new Security Factor", action: {})
							.buttonStyle(.blueText)

						WithControlRequirements(
							store.selectedFactorSource,
							forAction: { store.send(.view(.continueButtonTapped($0))) }
						) { action in
							Button(L10n.Common.continue, action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
				}
				.onFirstAppear {
					store.send(.view(.appeared))
				}
				.background(.secondaryBackground)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .small1) {
				topView

				Selection(
					$store.selectedFactorSource.sending(\.view.selectedFactorSourceChanged),
					from: store.factorSourcesCandidates
				) { item in
					VStack {
						let isFirstOfKind = store.factorSourcesCandidates.first(where: { $0.factorSourceKind == item.value.factorSourceKind }) == item.value
						if isFirstOfKind {
							VStack(alignment: .leading, spacing: .zero) {
								Text(item.value.factorSourceKind.title)
									.textStyle(.body1HighImportance)
								Text(item.value.factorSourceKind.details)
									.textStyle(.body1Regular)
							}
							.foregroundStyle(.secondaryText)
							.padding(.top, .medium3)
							.flushedLeft
						}

						FactorSourceCard(
							kind: .instance(factorSource: item.value, kind: .short(showDetails: false)),
							mode: .selection(
								type: .radioButton,
								isSelected: item.isSelected
							)
						)
						.embedInButton(when: item.action)
						.buttonStyle(.inert)
					}
				}
			}
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .small3) {
				Text("Select Security Factor")
					.textStyle(.sheetTitle)

				Text(markdown: "Choose the security factor you will use to create the new Account.", emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
					.textStyle(.body1Regular)
					.lineSpacing(.zero)
			}
			.foregroundStyle(.primaryText)
			.multilineTextAlignment(.center)
		}
	}
}
