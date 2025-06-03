import SwiftUI

struct AssetRow<Accessory: View>: View {
	let name: String?
	let address: LedgerIdentifiable.Address
	let type: Thumbnail.ContentType
	let url: URL?
	let accessory: Accessory?

	init(
		name: String?,
		address: LedgerIdentifiable.Address,
		type: Thumbnail.ContentType,
		url: URL?,
		@ViewBuilder accessory: () -> Accessory
	) {
		self.name = name
		self.address = address
		self.type = type
		self.url = url
		self.accessory = accessory()
	}

	var body: some SwiftUI.View {
		HStack(spacing: .zero) {
			Thumbnail(type, url: url)

			VStack(alignment: .leading, spacing: .zero) {
				Text(name ?? "-")
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)
					.lineLimit(1)

				AddressView(.address(address))
					.textStyle(.body2Regular)
					.foregroundColor(.secondaryText)
			}
			.padding(.horizontal, .small2)

			Spacer()

			if let accessory {
				accessory
			}
		}
		.padding(.medium3)
	}
}
