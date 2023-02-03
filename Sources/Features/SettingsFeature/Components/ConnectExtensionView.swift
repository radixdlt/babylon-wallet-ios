import FeaturePrelude

// MARK: - ConnectExtensionView
struct ConnectExtensionView: View {
	let action: () -> Void
}

extension ConnectExtensionView {
	var body: some View {
		VStack(spacing: .medium2) {
			Image(asset: AssetResource.browsers)
				.padding([.top, .horizontal], .medium1)

			Text(L10n.Settings.ConnectExtension.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .medium2)

			Text(L10n.Settings.ConnectExtension.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .medium2)

			Button(L10n.Settings.ConnectExtension.buttonTitle) {
				action()
			}
			.buttonStyle(.secondaryRectangular(
				shouldExpand: true,
				image: .init(asset: AssetResource.qrCodeScanner)
			)
			)
			.padding([.bottom, .horizontal], .medium1)
		}
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ConnectExtensionView_Previews: PreviewProvider {
	static var previews: some View {
		ConnectExtensionView {}
	}
}
#endif
