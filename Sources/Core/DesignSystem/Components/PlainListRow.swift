import Resources
import SwiftUI

// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	let chevron: Bool
	let title: String
	let icon: Icon
	let action: () -> Void

	public init(withChevron chevron: Bool = true,
	            title: String, action: @escaping () -> Void,
	            @ViewBuilder icon: () -> Icon)
	{
		self.chevron = chevron
		self.title = title
		self.icon = icon()
		self.action = action
	}

	public init(withChevron chevron: Bool = true,
	            title: String, asset: ImageAsset,
	            action: @escaping () -> Void) where Icon == AssetIcon
	{
		self.chevron = chevron
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
				if chevron {
					Image(asset: AssetResource.chevronRight)
				}
			}
			.frame(height: .largeButtonHeight)
		}
		.padding(.horizontal, .medium3)
	}
}

public extension PlainListRow {
	var withSeparator: some View {
		VStack(spacing: .zero) {
			self
			Separator()
		}
	}
}
