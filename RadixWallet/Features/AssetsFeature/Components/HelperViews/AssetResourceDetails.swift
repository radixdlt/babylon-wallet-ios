import ComposableArchitecture
import SwiftUI

// MARK: - AssetResourceDetailsSection
struct AssetResourceDetailsSection: View {
	let viewState: ViewState

	struct ViewState: Equatable {
		let description: Loadable<String?>
		let infoUrl: Loadable<URL?>
		let resourceAddress: ResourceAddress
		let isXRD: Bool
		let validatorAddress: ValidatorAddress?
		let resourceName: Loadable<String?>?
		let currentSupply: Loadable<String?>
		let arbitraryDataFields: Loadable<[ArbitraryDataField]>
		let behaviors: Loadable<[AssetBehavior]>
		let tags: Loadable<[AssetTag]>
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .medium1) {
			AssetDetailsSeparator()

			loadable(viewState.description) { description in
				if let description {
					VStack(alignment: .leading, spacing: .medium2) {
						Text(description)
							.textStyle(.body1Regular)

						if let wrappedValue = viewState.infoUrl.wrappedValue, let infoUrl = wrappedValue {
							KeyValueUrlView(key: L10n.AssetDetails.moreInfo, url: infoUrl, isLocked: false)
						}
					}

					AssetDetailsSeparator()
						.padding(.horizontal, -.large2)
				}
			}
			.padding(.horizontal, .large2)

			VStack(alignment: .leading, spacing: .medium3) {
				KeyValueView(resourceAddress: viewState.resourceAddress)

				if let validatorAddress = viewState.validatorAddress {
					KeyValueView(validatorAddress: validatorAddress)
				}

				if let resourceName = viewState.resourceName {
					loadable(resourceName) { value in
						if let value {
							KeyValueView(key: L10n.AssetDetails.NFTDetails.resourceName, value: value)
						}
					}
				}

				loadable(viewState.currentSupply) { supply in
					KeyValueView(key: L10n.AssetDetails.currentSupply, value: supply ?? "")
				}

				loadable(viewState.behaviors) { value in
					AssetBehaviorsView(behaviors: value, isXRD: viewState.isXRD)
				}

				loadable(viewState.tags) { _ in
					AssetTagsView(tags: viewState.tags.wrappedValue ?? [])
				}

				loadable(viewState.arbitraryDataFields) { arbitraryDataFields in
					if !arbitraryDataFields.isEmpty {
						AssetDetailsSeparator()
							.padding(.vertical, .small2)
							.padding(.horizontal, -.large2)

						ForEachStatic(arbitraryDataFields) { field in
							ArbitraryDataFieldView(field: field)
						}
					}
				}
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
