import ComposableArchitecture
import SwiftUI

// MARK: - KeyValueView
@MainActor
struct KeyValueView<Content: View>: View {
	let key: String
	let content: Content

	init(resourceAddress: ResourceAddress, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.resourceAddress) {
			AddressView(.address(.resource(resourceAddress)), imageColor: imageColor)
		}
	}

	init(validatorAddress: ValidatorAddress, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.validator) {
			AddressView(.address(.validator(validatorAddress)), imageColor: imageColor)
		}
	}

	init(nonFungibleGlobalID: NonFungibleGlobalId, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.NFTDetails.id) {
			AddressView(.address(.nonFungibleGlobalID(nonFungibleGlobalID)), imageColor: imageColor)
		}
	}

	init(key: String, value: String) where Content == Text {
		self.key = key
		self.content = Text(value)
	}

	init(key: String, @ViewBuilder content: () -> Content) {
		self.key = key
		self.content = content()
	}

	var body: some View {
		HStack(alignment: .top, spacing: .medium3) {
			Text(key)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)
			Spacer(minLength: 0)
			content
				.multilineTextAlignment(.trailing)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
				.lineLimit(nil)
		}
	}
}
