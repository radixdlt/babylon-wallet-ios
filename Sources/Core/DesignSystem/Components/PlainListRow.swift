import Resources
import SwiftUI

// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	let isShowingChevron: Bool
	let title: String
	let icon: Icon

	public init(
		showChevron: Bool = true,
		title: String,
		@ViewBuilder icon: () -> Icon
	) {
		self.isShowingChevron = showChevron
		self.title = title
		self.icon = icon()
	}

	public init(
		showChevron: Bool = true,
		title: String,
		asset: ImageAsset
	) where Icon == AssetIcon {
		self.isShowingChevron = showChevron
		self.title = title
		self.icon = AssetIcon(asset: asset)
	}

	public var body: some View {
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

extension PlainListRow {
	public func tappable(_ action: @escaping () -> Void) -> some View {
		Button(action: action) {
			self
		}
		.buttonStyle(.tappableRowStyle)
	}
}

extension View {
	/// Adds a separator below the view, without padding. The separator has horizontal padding of default size.
	public var withSeparator: some View {
		withSeparator()
	}

	/// Adds a separator below the view, without padding. The separator has horizontal padding of of the provided size.
	public func withSeparator(horizontalPadding: CGFloat = .medium3) -> some View {
		VStack(spacing: .zero) {
			self
			Separator()
				.padding(.horizontal, horizontalPadding)
		}
	}
}

// MARK: - PlainListRow_Previews
struct PlainListRow_Previews: PreviewProvider {
	static var previews: some View {
		PlainListRow(
			showChevron: true,
			title: "A title",
			asset: AssetResource.generalSettings
		)
	}
}
