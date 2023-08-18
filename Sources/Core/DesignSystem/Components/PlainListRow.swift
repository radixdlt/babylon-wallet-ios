import Resources
import SwiftUI

// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	let accessory: ImageAsset?
	let title: String
	let subtitle: String?
	let icon: Icon?

	public init(
		title: String,
		subtitle: String? = nil,
		accessory: ImageAsset? = AssetResource.chevronRight,
		@ViewBuilder icon: () -> Icon
	) {
		self.accessory = accessory
		self.title = title
		self.subtitle = subtitle
		self.icon = icon()
	}

	public init(
		_ content: AssetIcon.Content?,
		title: String,
		subtitle: String? = nil,
		accessory: ImageAsset? = AssetResource.chevronRight
	) where Icon == AssetIcon {
		self.accessory = accessory
		self.title = title
		self.subtitle = subtitle
		self.icon = content.map { AssetIcon($0) }
	}

	public var body: some View {
		HStack(spacing: .zero) {
			if let icon {
				icon
					.padding(.trailing, .medium3)
			}
			VStack(alignment: .leading, spacing: .zero) {
				Text(title)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
				if let subtitle {
					Text(subtitle)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
			}
			Spacer(minLength: .medium3)
			if let accessory {
				Image(asset: accessory)
			}
		}
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
			.asset(AssetResource.generalSettings),
			title: "A title"
		)
	}
}
