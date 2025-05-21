import SwiftUI

extension InteractionReview {
	struct RawManifestView: SwiftUI.View {
		@Dependency(\.pasteboardClient) var pasteboardClient

		let manifest: String
		let toggleAction: (() -> Void)?

		init(
			manifest: String,
			toggleAction: (() -> Void)? = nil
		) {
			self.manifest = manifest
			self.toggleAction = toggleAction
		}

		var body: some View {
			VStack(alignment: .leading, spacing: .medium1) {
				HStack(spacing: .small2) {
					Spacer()
					copyButton
					toggleButton
				}

				content
					.padding(.horizontal, .small1)
			}
			.padding([.top, .horizontal], .medium3)
			.padding(.bottom, .medium1)
			.frame(maxWidth: .infinity)
		}

		private var copyButton: some View {
			Button {
				pasteboardClient.copyString(manifest)
			} label: {
				HStack(spacing: .small3) {
					AssetIcon(.asset(.copy))
					Text(L10n.Common.copy)
						.textStyle(.body1Header)
				}
				.foregroundColor(.primaryText)
			}
			.buttonStyle(.secondaryRectangular)
		}

		private var toggleButton: some View {
			Group {
				if let toggleAction {
					Button(asset: AssetResource.iconTxnBlocks, action: toggleAction)
						.buttonStyle(.secondaryRectangular)
				}
			}
		}

		private var content: some View {
			Text(manifest)
				.textStyle(.monospace)
				.foregroundColor(.primaryText)
				.multilineTextAlignment(.leading)
				.textSelection(.enabled)
		}
	}
}
