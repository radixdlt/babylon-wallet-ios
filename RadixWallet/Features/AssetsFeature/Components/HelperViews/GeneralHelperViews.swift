import ComposableArchitecture
import SwiftUI

// MARK: - KeyValueView
@MainActor
struct KeyValueView<Content: View>: View {
	let axis: Axis
	let key: String
	let content: Content
	let isLocked: Bool

	init(resourceAddress: ResourceAddress, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.resourceAddress, isLocked: false) {
			AddressView(.address(.resource(resourceAddress)), imageColor: imageColor)
		}
	}

	init(validatorAddress: ValidatorAddress, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.validator, isLocked: false) {
			AddressView(.address(.validator(validatorAddress)), imageColor: imageColor)
		}
	}

	init(nonFungibleGlobalID: NonFungibleGlobalId, showLocalIdOnly: Bool, imageColor: Color? = .app.gray2) where Content == AddressView {
		self.init(key: L10n.AssetDetails.NFTDetails.id, isLocked: false) {
			AddressView(.address(.nonFungibleGlobalID(nonFungibleGlobalID)), showLocalIdOnly: showLocalIdOnly, imageColor: imageColor)
		}
	}

	init(axis: Axis = .horizontal, key: String, value: String, isLocked: Bool = false) where Content == Text {
		self.axis = axis
		self.key = key
		self.isLocked = isLocked
		self.content = Text(value)
	}

	init(axis: Axis = .horizontal, key: String, isLocked: Bool = false, @ViewBuilder content: () -> Content) {
		self.axis = axis
		self.key = key
		self.isLocked = isLocked
		self.content = content()
	}

	var body: some View {
		switch axis {
		case .horizontal:
			HStack(alignment: .top, spacing: .medium3) {
				KeyText(key: key, isLocked: isLocked)
				Spacer(minLength: 0)
				content
					.multilineTextAlignment(.trailing)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
					.lineLimit(nil)
			}
		case .vertical:
			VStack(alignment: .leading, spacing: .small3) {
				KeyText(key: key, isLocked: isLocked)

				content
					.multilineTextAlignment(.trailing)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
					.lineLimit(nil)
			}
			.flushedLeft
		}
	}
}

// MARK: - KeyValueTruncatedView
struct KeyValueTruncatedView: View {
	let key: String
	let value: String
	let isLocked: Bool

	@Dependency(\.pasteboardClient) var pasteboardClient

	var body: some View {
		HStack(alignment: .top, spacing: .medium3) {
			KeyText(key: key, isLocked: isLocked)

			Spacer(minLength: 0)

			Text(value)
				.multilineTextAlignment(.trailing)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
				.lineLimit(1)
				.onTapGesture {
					pasteboardClient.copyString(value)
				}
		}
	}
}

// MARK: - KeyValueUrlView
struct KeyValueUrlView: View {
	let key: String
	let url: URL
	let isLocked: Bool

	@Dependency(\.openURL) var openURL

	var body: some View {
		KeyValueView(axis: .vertical, key: key, isLocked: isLocked) {
			Button(url.absoluteString) {
				openUrl(url)
			}
			.multilineTextAlignment(.leading)
			.buttonStyle(.url)
		}
	}

	private func openUrl(_ url: URL) {
		Task {
			await openURL(url)
		}
	}
}

// MARK: - KeyText
private struct KeyText: View {
	let key: String
	let isLocked: Bool

	var body: some View {
		HStack(spacing: .small3) {
			Text(key)
				.textStyle(.body1Regular)

			if isLocked {
				Image(.lockMetadata)
			}
		}
		.foregroundColor(.app.gray2)
	}
}
