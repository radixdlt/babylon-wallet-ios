import SwiftUI
import Resources

// MARK: - View

public struct PlainListRow<Icon: View>: View {
	let title: String
	let icon: Icon
	let action: () -> Void
	
	public init(title: String, @ViewBuilder icon: () -> Icon, action: @escaping () -> Void) {
		self.title = title
		self.icon = icon()
		self.action = action
	}
	
	public init(title: String, asset: ImageAsset, action: @escaping () -> Void) where Icon == AssetIcon {
		self.title = title
		self.icon = AssetIcon(asset: asset)
		self.action = action
	}
}

public struct AssetIcon: View {
	private let asset: ImageAsset
	private let hitTargetSize: HitTargetSize
	private let cornerRadius: CGFloat

	public init(asset: ImageAsset, verySmall: Bool = true) {
		self.asset = asset
		self.hitTargetSize = verySmall ? .verySmall : .small
		self.cornerRadius = verySmall ? .small3 : .small2
	}
	
	public var body: some View {
		Image(asset: asset)
			.frame(hitTargetSize)
			.cornerRadius(cornerRadius)
	}
}

// MARK: - Body

extension PlainListRow {
	public var body: some View {
		Button(action: action) {
			VStack(spacing: .zero) {
				HStack(spacing: .zero) {
					icon
						.padding(.trailing, .medium3)
					Text(title)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)
					Spacer()
					Image(asset: AssetResource.chevronRight)
				}
				.frame(height: .largeButtonHeight)
				Separator()
			}
			.foregroundColor(.app.gray1)
		}
	}
}
