import ComposableArchitecture
import SwiftUI

// MARK: - OnLedgerTagsView
struct OnLedgerTagsView: View {
	let tags: [OnLedgerTag]

	var body: some View {
		if !tags.isEmpty {
			Group {
				Text(L10n.AssetDetails.tags)
					.textStyle(.body1Regular)
					.foregroundColor(.secondaryText)

				FlowLayout(spacing: .small2) {
					ForEach(tags, id: \.self) { tag in
						OnLedgerTagView(tag: tag)
					}
				}
			}
			.transition(.opacity.combined(with: .scale(scale: 0.8)))
		}
	}
}

// MARK: - OnLedgerTagView
struct OnLedgerTagView: View {
	let tag: OnLedgerTag

	var body: some View {
		HStack(spacing: .small2) {
			Image(asset: tag.icon)

			Text(tag.name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.secondaryText)
		}
		.padding(.vertical, .small3)
		.padding(.horizontal, .small1)
		.background {
			Bullet()
				.stroke(.border)
		}
	}
}

extension OnLedgerTag {
	var name: String {
		switch self {
		case .officialRadix:
			L10n.AssetDetails.Tags.officialRadix
		case let .custom(string):
			string.rawValue
		}
	}

	var icon: ImageAsset {
		switch self {
		case .officialRadix:
			AssetResource.officialTagIcon
		case .custom:
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
