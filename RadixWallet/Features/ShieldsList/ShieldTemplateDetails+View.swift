import SwiftUI

// MARK: - ShieldTemplateDetails.View
extension ShieldTemplateDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<ShieldTemplateDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(alignment: .leading) {
						VStack(alignment: .leading, spacing: .small1) {
							Text(store.structure.metadata.displayName.rawValue)
								.textStyle(.sheetTitle)
								.foregroundStyle(.primaryText)

							Button("Rename") {}
								.buttonStyle(.blueText)
						}
						.padding(.small1)

						Card {
							InnerCard {
								SecurityStructureOfFactorSourcesView(structure: store.structure)
							}
							.padding(.small1)
						}
					}
				}
				.footer {
					Button("Edit Factors") {}
						.buttonStyle(.primaryRectangular)
				}
				.background(.primaryBackground)
			}
		}
	}
}
