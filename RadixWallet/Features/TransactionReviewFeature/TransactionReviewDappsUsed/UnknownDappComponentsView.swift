import Foundation

struct UnknownDappComponentsView: View {
	let components: [ComponentAddress]

	init(components: [ComponentAddress]) {
		self.components = components
	}

	var body: some View {
		List(components) { component in
			HStack {
				DappThumbnail(.unknown)
				VStack {
					Text("Component")
					AddressView(.address(.component(component)))
				}
				Image(asset: AssetResource.iconLinkOut)
			}
		}
	}
}
