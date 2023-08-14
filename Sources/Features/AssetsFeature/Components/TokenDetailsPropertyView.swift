import EngineKit
import FeaturePrelude
import Resources

// MARK: - TokenDetailsPropertyViewMaker
enum TokenDetailsPropertyViewMaker {
	static func makeResourceAddress(address: ResourceAddress) -> some View {
		makeAddressView(
			title: L10n.AssetDetails.resourceAddress,
			address: .resource(address)
		)
	}

	static func makeValidatorAddress(address: ValidatorAddress) -> some View {
		makeAddressView(
			// FIXME: L10n.Account.PoolUnits.validatorAddress
			title: "Validator",
			address: .validator(address)
		)
	}

	private static func makeAddressView(
		title: String,
		address: LedgerIdentifiable.Address
	) -> some View {
		TokenDetailsPropertyView(
			title: title,
			propertyView: AddressView(.address(address))
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
