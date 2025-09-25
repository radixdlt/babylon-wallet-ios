import SwiftUI

extension ApplyShield {
	struct CompletionView: SwiftUI.View {
		let factorSources: FactorSources
		let action: () -> Void

		var body: some SwiftUI.View {
			ScrollView {
				VStack(spacing: .huge2) {
					VStack(spacing: .medium2) {
						Text(L10n.ShieldWizardApplyShield.ApplyShield.title)
							.textStyle(.sheetTitle)

						Text(L10n.ShieldWizardApplyShield.ApplyShield.subtitle)
							.textStyle(.body1HighImportance)
					}
					.foregroundStyle(.primaryText)
					.multilineTextAlignment(.center)

					VStack {
						ForEach(factorSources) { factorSource in
							FactorSourceCard(kind: .instance(factorSource: factorSource, kind: .short(showDetails: false)), mode: .display)
						}
					}
				}
				.padding(.horizontal, .large2)
			}
			.background(.secondaryBackground)
			.footer {
				Button("Apply", action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
