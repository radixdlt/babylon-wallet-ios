import ComposableArchitecture
import SwiftUI

// MARK: - AssetTagsView
struct AssetTagsView: View {
	let tags: [AssetTag]

	var body: some View {
		if !tags.isEmpty {
			Group {
				Text(L10n.AssetDetails.tags)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray2)

				FlowLayout(spacing: .small2) {
					ForEach(tags, id: \.self) { tag in
						AssetTagView(tag: tag)
					}
				}
			}
			.transition(.opacity.combined(with: .scale(scale: 0.8)))
		}
	}
}

// MARK: - AssetTagView
struct AssetTagView: View {
	let tag: AssetTag

	var body: some View {
		HStack(spacing: .small2) {
			Image(asset: tag.icon)

			Text(tag.name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
		}
		.padding(.vertical, .small3)
		.padding(.horizontal, .small1)
		.background {
			Bullet()
				.stroke(.app.gray4)
		}
	}
}

extension AssetTag {
	public var name: String {
		switch self {
		case .officialRadix:
			"Official Radix" // FIXME: Strings

		case let .custom(string):
			string.rawValue
		}
	}

	public var icon: ImageAsset {
		if case .officialRadix = self {
			AssetResource.officialTagIcon
		} else {
			AssetResource.tagIcon
		}
	}
}

// MARK: - Bullet
struct Bullet: Shape {
	typealias Path = SwiftUI.Path

	func path(in rect: CGRect) -> Path {
		Path { path in
			let radius = 0.5 * rect.height
			path.addRelativeArc(
				center: .init(x: rect.maxX - radius, y: rect.midY),
				radius: radius,
				startAngle: .radians(-0.5 * .pi),
				delta: .radians(.pi)
			)
			let corner: CGFloat = .small3
			path.addRelativeArc(
				center: .init(x: rect.minX + corner, y: rect.maxY - corner),
				radius: corner,
				startAngle: .radians(0.5 * .pi),
				delta: .radians(0.5 * .pi)
			)
			path.addRelativeArc(
				center: .init(x: rect.minX + corner, y: rect.minY + corner),
				radius: corner,
				startAngle: .radians(.pi),
				delta: .radians(0.5 * .pi)
			)
			path.closeSubpath()
		}
	}
}
