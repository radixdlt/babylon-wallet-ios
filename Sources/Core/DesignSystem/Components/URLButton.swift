import Resources
import SwiftUI

public struct URLButton: View {
	let url: URL
	let action: () -> Void

	public init(url: URL, action: @escaping () -> Void) {
		self.url = url
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			Label {
				Text(url.absoluteString)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.blue2)
			} icon: {
				Image(asset: AssetResource.iconLinkOut)
					.foregroundColor(.app.gray2)
			}
			.labelStyle(.trailingIcon)
		}
	}
}
