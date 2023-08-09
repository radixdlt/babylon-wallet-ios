import EngineKit
import FeaturePrelude
import Resources

// MARK: - TokenDetailsPropertyViewMaker
enum TokenDetailsPropertyViewMaker {
	static func makeAddress(resourceAddress: ResourceAddress) -> some View {
		TokenDetailsPropertyView(
			title: L10n.AssetDetails.resourceAddress,
			propertyView: AddressView(.address(.resource(resourceAddress)))
		)
	}
}

// MARK: - TokenDetailsPropertyView
struct TokenDetailsPropertyView<PropertyView>: View where PropertyView: View {
	let title: String
	let propertyView: PropertyView

	var body: some View {
		HStack {
			Text(title)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)

			Spacer(minLength: .zero)

			propertyView
				.textStyle(.body1HighImportance)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.lineLimit(1)
	}
}
