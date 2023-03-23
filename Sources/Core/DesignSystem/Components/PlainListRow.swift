import Resources
import SwiftUI

// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	let isShowingChevron: Bool
	let title: String
	let icon: Icon
	let action: () -> Void

	public init(showChevron: Bool = true,
	            title: String,
	            action: @escaping () -> Void,
	            @ViewBuilder icon: () -> Icon)
	{
		self.isShowingChevron = showChevron
		self.title = title
		self.icon = icon()
		self.action = action
	}

	public init(showChevron: Bool = true,
	            title: String,
	            asset: ImageAsset,
	            action: @escaping () -> Void) where Icon == AssetIcon
	{
		self.isShowingChevron = showChevron
		self.title = title
		self.icon = AssetIcon(asset: asset)
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			HStack(spacing: .zero) {
				icon
					.padding(.trailing, .medium3)
				Text(title)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
				Spacer(minLength: 0)
				if isShowingChevron {
					Image(asset: AssetResource.chevronRight)
				}
			}
			.frame(height: .largeButtonHeight)
			.padding(.horizontal, .medium3)
		}
	}
}

extension PlainListRow {
	public var withSeparator: some View {
		VStack(spacing: .zero) {
			self
			Separator()
				.padding(.horizontal, .medium3)
		}
	}
}

// MARK: - PlainListRow_Previews
struct PlainListRow_Previews: PreviewProvider {
	static var previews: some View {
		PlainListRow(
			showChevron: true,
			title: "A title",
			asset: AssetResource.generalSettings,
			action: {}
		)
	}
}
