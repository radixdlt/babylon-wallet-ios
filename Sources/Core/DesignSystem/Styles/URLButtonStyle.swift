import Resources
import SwiftUI

// MARK: - URLButtonStyle
public struct URLButtonStyle: ButtonStyle {
	public func makeBody(configuration: Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.blue2)
		} icon: {
			Image(asset: AssetResource.iconLinkOut)
				.foregroundColor(.app.gray2)
		}
		.labelStyle(.trailingIcon)
	}
}

extension ButtonStyle where Self == URLButtonStyle {
	public static var url: URLButtonStyle { .init() }
}
