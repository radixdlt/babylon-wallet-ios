import EngineKit
import FeaturePrelude
import SharedModels

// MARK: - AssetResourceDetailsSection
struct AssetResourceDetailsSection: View {
	let viewState: ViewState

	struct ViewState: Equatable {
		let description: String?
		let resourceAddress: ResourceAddress
		let validatorAddress: ValidatorAddress?
		let resourceName: String?
		let currentSupply: String?
		let behaviors: [AssetBehavior]
		let tags: [AssetTag]
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .medium1) {
			AssetDetailsSeparator()

			if let description = viewState.description {
				Text(description)
					.textStyle(.body1Regular)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, .large2)

				AssetDetailsSeparator()
			}

			VStack(alignment: .leading, spacing: .medium3) {
				KeyValueView(resourceAddress: viewState.resourceAddress)

				if let validatorAddress = viewState.validatorAddress {
					KeyValueView(validatorAddress: validatorAddress)
				}

				if let resourceName = viewState.resourceName {
					KeyValueView(key: "Name", value: resourceName) // FIXME: Strings - make a common name string for all asset details, remove the specific one(s)
				}

				if let currentSupply = viewState.currentSupply {
					KeyValueView(
						key: L10n.AssetDetails.currentSupply,
						value: currentSupply
					)
				}

				AssetBehaviorsView(behaviors: viewState.behaviors)

				AssetTagsView(tags: viewState.tags)
			}
			.padding(.horizontal, .large2)
		}
	}
}

// MARK: - AssetDetailsSeparator
struct AssetDetailsSeparator: View {
	var body: some View {
		Color.app.gray4
			.frame(height: 1)
			.padding(.horizontal, .medium1)
	}
}
