import SwiftUI

/// A view used to represent arbitrary data, which is a key/value pair that isn't standarized by the Wallet.
/// These can be found inside a resource metadata or in NFTs.
public struct ArbitraryDataFieldView: View {
	let field: Field

	public var body: some View {
		switch field.kind {
		case let .primitive(value):
			ViewThatFits(in: .horizontal) {
				KeyValueView(key: field.name, value: value)
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
			KeyValueTruncatedView(key: field.name, value: value)

		case .complex:
			KeyValueView(key: field.name, value: L10n.AssetDetails.NFTDetails.complexData)

		case let .url(url):
			VStack(alignment: .leading, spacing: .small3) {
				Text(field.name)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray2)
				Button(url.absoluteString) {
					openUrl(url)
				}
				.buttonStyle(.url)
			}
			.flushedLeft

		case let .address(address):
			KeyValueView(key: field.name) {
				AddressView(.address(address), imageColor: .app.gray2)
			}

		case let .decimal(value):
			KeyValueView(key: field.name, value: value.formatted())

		case let .enum(variant):
			KeyValueView(key: field.name, value: variant)

		case let .id(id):
			KeyValueView(key: field.name, value: id.toRawString()) // use `id.formatted()` instead?

		case let .instant(date):
			KeyValueView(key: field.name, value: date.formatted())
		}
	}

	private func openUrl(_ url: URL) {
		@Dependency(\.openURL) var openURL
		Task {
			await openURL(url)
		}
	}
}
