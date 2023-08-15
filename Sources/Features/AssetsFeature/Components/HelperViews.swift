import EngineKit
import FeaturePrelude
import SharedModels

// MARK: - NFTFullView
struct NFTFullView: View {
	let url: URL
	let minAspect: CGFloat
	let maxAspect: CGFloat

	init(url: URL, minAspect: CGFloat = .zero, maxAspect: CGFloat = .infinity) {
		self.url = url
		self.minAspect = minAspect
		self.maxAspect = maxAspect
	}

	var body: some View {
		LoadableImage(
			url: url,
			size: .flexible(minAspect: minAspect, maxAspect: maxAspect),
			placeholders: .init(loading: .shimmer)
		)
		.cornerRadius(.small1)
	}
}

// MARK: - NFTIDView
struct NFTIDView: View {
	let id: String
	let name: String?
	let description: String?
	let thumbnail: URL?

	var body: some View {
		VStack(spacing: .small1) {
			if let thumbnail {
				NFTFullView(
					url: thumbnail,
					minAspect: minImageAspect,
					maxAspect: maxImageAspect
				)
				.padding(.bottom, .small1)
			}
			KeyValueView(key: L10n.AssetDetails.NFTDetails.id, value: id)
		}
	}

	private let minImageAspect: CGFloat = 1
	private let maxImageAspect: CGFloat = 16 / 9
}

// MARK: - KeyValueView
struct KeyValueView<Content: View>: View {
	let key: String
	let content: Content

	init(resourceAddress: ResourceAddress) where Content == AddressView {
		self.init(key: L10n.AssetDetails.resourceAddress) {
			AddressView(.address(.resource(resourceAddress)))
		}
	}

	init(validatorAddress: ValidatorAddress) where Content == AddressView {
		self.init(key: "Validator") { // FIXME: Strings - L10n.Account.PoolUnits.validatorAddress
			AddressView(.address(.validator(validatorAddress)))
		}
	}

	init(key: String, value: String) where Content == Text {
		self.key = key
		self.content = Text(value)
	}

	init(key: String, @ViewBuilder content: () -> Content) {
		self.key = key
		self.content = content()
	}

	var body: some View {
		HStack(alignment: .top, spacing: 0) {
			Text(key)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)
			Spacer(minLength: 0)
			content
				.multilineTextAlignment(.trailing)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
		}
	}
}

// MARK: - AssetBehaviorSection
struct AssetBehaviorSection: View {
	let behaviors: [AssetBehavior]

	var body: some View {
		if !behaviors.isEmpty {
			Text(L10n.AssetDetails.behavior)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)

			VStack(alignment: .leading, spacing: .small1) {
				ForEach(behaviors, id: \.self) { behavior in
					AssetBehaviorRow(behavior: behavior)
				}
			}
		}
	}
}

// MARK: - AssetBehaviorRow
struct AssetBehaviorRow: View {
	let behavior: AssetBehavior

	var body: some View {
		HStack(spacing: .medium3) {
			Image(asset: behavior.icon)

			Text(behavior.description)
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

extension AssetBehavior {
	public var description: String {
		switch self {
		case .simpleAsset:
			return L10n.AccountSettings.Behaviors.simpleAsset
		case .supplyIncreasable:
			return L10n.AccountSettings.Behaviors.supplyIncreasable
		case .supplyDecreasable:
			return L10n.AccountSettings.Behaviors.supplyDecreasable
		case .supplyIncreasableByAnyone:
			return L10n.AccountSettings.Behaviors.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone:
			return L10n.AccountSettings.Behaviors.supplyDecreasableByAnyone
		case .supplyFlexible:
			return L10n.AccountSettings.Behaviors.supplyFlexible
		case .supplyFlexibleByAnyone:
			return L10n.AccountSettings.Behaviors.supplyFlexibleByAnyone
		case .movementRestricted:
			return L10n.AccountSettings.Behaviors.movementRestricted
		case .movementRestrictableInFuture:
			return L10n.AccountSettings.Behaviors.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone:
			return L10n.AccountSettings.Behaviors.movementRestrictableInFutureByAnyone
		case .removableByThirdParty:
			return L10n.AccountSettings.Behaviors.removableByThirdParty
		case .removableByAnyone:
			return L10n.AccountSettings.Behaviors.removableByAnyone
		case .freezableByThirdParty:
			return "A third party can freeze this asset in place." // FIXME: Strings ... .freezableByThirdParty
		case .freezableByAnyone:
			return "Anyone can freeze this asset in place." // FIXME: Strings ... .freezableByAnyone
		case .nftDataChangeable:
			return L10n.AccountSettings.Behaviors.nftDataChangeable
		case .nftDataChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.nftDataChangeableByAnyone

		case .informationChangeable:
			return L10n.AccountSettings.Behaviors.informationChangeable
		case .informationChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.informationChangeableByAnyone
		}
	}

	public var icon: ImageAsset {
		switch self {
		case .simpleAsset: return AssetResource.simpleAsset
		case .supplyIncreasable: return AssetResource.supplyIncreasable
		case .supplyDecreasable: return AssetResource.supplyDecreasable
		case .supplyIncreasableByAnyone: return AssetResource.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone: return AssetResource.supplyDecreasableByAnyone
		case .supplyFlexible: return AssetResource.supplyFlexible
		case .supplyFlexibleByAnyone: return AssetResource.supplyFlexibleByAnyone
		case .movementRestrictableInFuture: return AssetResource.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone: return AssetResource.movementRestrictableInFutureByAnyone
		case .movementRestricted: return AssetResource.movementRestricted
		case .removableByThirdParty: return AssetResource.removableByThirdParty
		case .removableByAnyone: return AssetResource.removableByAnyone
		case .freezableByThirdParty: return AssetResource.removableByThirdParty // FIXME: icons
		case .freezableByAnyone: return AssetResource.removableByAnyone // FIXME: icons
		case .nftDataChangeable: return AssetResource.nftDataChangeable
		case .nftDataChangeableByAnyone: return AssetResource.nftDataChangeableByAnyone

		case .informationChangeable: return AssetResource.informationChangeable
		case .informationChangeableByAnyone: return AssetResource.informationChangeableByAnyone
		}
	}
}

// MARK: - AssetTagsSection
struct AssetTagsSection: View {
	let tags: [AssetTag]

	var body: some View {
		if !tags.isEmpty {
			Text(L10n.AssetDetails.tags)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)

			FlowLayout(spacing: .small2) {
				ForEach(tags, id: \.self) { tag in
					AssetTagView(tag: tag)
				}
			}
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
			return "Official Radix" // FIXME: Strings

		case let .custom(string):
			return string
		}
	}

	public var icon: ImageAsset {
		if case .officialRadix = self {
			return AssetResource.officialTagIcon
		} else {
			return AssetResource.tagIcon
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
