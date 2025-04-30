import Sargon
import SwiftUI

// MARK: - FactorSourcePreviewCard
struct FactorSourcePreviewCard: View {
	let factorSource: FactorSource

	var body: some View {
		HStack(alignment: .center, spacing: .small2) {
			Image(factorSource.factorSourceKind.icon)

			Text(factorSource.name)
				.textStyle(.body1Header)
				.foregroundStyle(.primaryText)
				.flushedLeft
		}
		.padding(.medium3)
		.background(.primaryBackground)
		.roundedCorners(strokeColor: .borderColor, radius: .small1)
	}
}
