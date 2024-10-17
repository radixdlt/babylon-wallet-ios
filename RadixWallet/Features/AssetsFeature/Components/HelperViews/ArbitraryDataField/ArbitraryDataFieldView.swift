import SwiftUI

// MARK: - ArbitraryDataFieldView
/// A view used to represent arbitrary data, which is a key/value pair that isn't standarized by the Wallet.
/// These can be found inside a resource metadata or in NFTs.
struct ArbitraryDataFieldView: View {
	let field: Field

	var body: some View {
		switch field.kind {
		case let .primitive(value):
			ViewThatFits(in: .horizontal) {
				KeyValueView(key: field.name, value: value, isLocked: field.isLocked)
				VStack(alignment: .leading, spacing: .small3) {
					Text(field.name)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
					ExpandableTextView(
						fullText: value
					)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
				}
				.flushedLeft
			}

		case let .truncated(value):
			KeyValueTruncatedView(key: field.name, value: value, isLocked: field.isLocked)

		case .complex:
			KeyValueView(key: field.name, value: L10n.AssetDetails.NFTDetails.complexData, isLocked: field.isLocked)

		case let .url(url):
			KeyValueUrlView(key: field.name, url: url, isLocked: field.isLocked)

		case let .address(address):
			KeyValueView(axis: address.axis, key: field.name, isLocked: field.isLocked) {
				AddressView(.address(address), imageColor: .app.gray2)
			}

		case let .decimal(value):
			KeyValueView(key: field.name, value: value.formatted(), isLocked: field.isLocked)

		case let .enum(variant):
			KeyValueView(key: field.name, value: variant, isLocked: field.isLocked)

		case let .id(id):
			KeyValueView(key: field.name, value: id.toRawString(), isLocked: field.isLocked) // use `id.formatted()` instead?

		case let .instant(date):
			KeyValueView(key: field.name, value: date.formatted(), isLocked: field.isLocked)
		}
	}
}

private extension LedgerIdentifiable.Address {
	var axis: Axis {
		switch self {
		case .nonFungibleGlobalID: .vertical
		default: .horizontal
		}
	}
}
