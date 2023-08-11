import Resources
import SwiftUI

// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	let isShowingChevron: Bool
	let title: String
	let subtitle: String?
	let icon: Icon

	public init(
		title: String,
		showChevron: Bool = true,
		subtitle: String? = nil,
		@ViewBuilder icon: () -> Icon
	) {
		self.isShowingChevron = showChevron
		self.title = title
		self.subtitle = subtitle
		self.icon = icon()
	}

	public init(
		_ content: AssetIcon.Content,
		title: String,
		subtitle: String? = nil,
		showChevron: Bool = true
	) where Icon == AssetIcon {
		self.init(
			title: title,
			showChevron: showChevron,
			subtitle: subtitle,
			icon: { AssetIcon(content) }
		)
	}

	public var body: some View {
		HStack(spacing: .zero) {
			icon
				.padding(.trailing, .medium3)

			PlainListRowCore(title: title, subtitle: subtitle)

			Spacer(minLength: 0)

			if isShowingChevron {
				Image(asset: AssetResource.chevronRight)
			}
		}
		.frame(minHeight: .largeButtonHeight)
		.padding(.horizontal, .medium3)
	}
}

// MARK: - PlainListRowCore
struct PlainListRowCore: View {
	let title: String
	let subtitle: String?

	var body: some View {
		VStack(alignment: .leading, spacing: .zero) {
			Text(title)
				.lineSpacing(-6)
				.lineLimit(1)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)

			if let subtitle {
				Text(subtitle)
					.lineSpacing(-4)
					.lineLimit(2)
					.minimumScaleFactor(0.8)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray2)
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
			.asset(AssetResource.appSettings),
			title: "A title",
			showChevron: true
		)
	}
}
