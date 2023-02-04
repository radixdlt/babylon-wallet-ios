import SwiftUI
import Resources

// MARK: - View

public struct PlainListRow<Icon: View>: View {
	let title: String
	let icon: Icon
	let verySmall: Bool
	let action: () -> Void
	
	public init(_ title: String, icon: Icon, verySmall: Bool = true, action: @escaping () -> Void) {
		self.title = title
		self.icon = icon
		self.verySmall = verySmall
		self.action = action
	}
	
	public init(_ title: String,asset: ImageAsset,action: @escaping () -> Void) where Icon == Image {
		self.init(title, icon: Image(asset: asset), action: action)
	}
}

// MARK: - Body

extension PlainListRow {
	public var body: some View {
		Button(action: action) {
			VStack(spacing: .zero) {
				HStack(spacing: .zero) {
					icon
						.frame(verySmall ? .verySmall : .small)
						.cornerRadius(verySmall ? .small3 : .small2)
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
