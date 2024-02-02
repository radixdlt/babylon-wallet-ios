import NukeUI
import SwiftUI

// MARK: - Thumbnail
public struct Thumbnail: View {
	private let type: ContentType
	private let url: URL?
	private let size: HitTargetSize

	public enum FungibleContent: Sendable, Hashable {
		case token(TokenContent)
		case poolUnit(URL?)
		case lsu(URL?)
	}

	public enum TokenContent: Sendable, Hashable {
		case xrd
		case other(URL?)
	}

	public enum ContentType: Sendable, Hashable {
		case token(Token)
		case poolUnit
		case lsu
		case nft
		case persona
		case dapp
		case pool
		case validator

		public enum Token: Sendable, Hashable {
			case xrd
			case other
		}
	}

	public init(fungible: FungibleContent, size: HitTargetSize = .small) {
		switch fungible {
		case let .token(token):
			self.init(token: token, size: size)
		case let .poolUnit(url):
			self.init(.poolUnit, url: url, size: size)
		case let .lsu(url):
			self.init(.lsu, url: url, size: size)
		}
	}

	public init(token: TokenContent, size: HitTargetSize = .small) {
		switch token {
		case .xrd:
			self.init(.token(.xrd), url: nil, size: size)
		case let .other(url):
			self.init(.token(.other), url: url, size: size)
		}
	}

	public init(_ type: ContentType, url: URL?, size: HitTargetSize = .small) {
		self.type = type
		self.url = url
		self.size = size
	}

	public var body: some View {
		switch type {
		case .token(.xrd):
			Image(asset: AssetResource.xrd)
				.resizable()
				.frame(size)

		case .token(.other):
			circularImage(placeholder: AssetResource.token)

		case .poolUnit, .lsu:
			circularImage(placeholder: AssetResource.poolUnits, placeholderBackground: true)

		case .nft:
			roundedRectImage(placeholder: AssetResource.nft, placeholderBackground: true)

		case .persona:
			circularImage(placeholder: AssetResource.persona)

		case .dapp, .pool:
			roundedRectImage(placeholder: AssetResource.unknownComponent)

		case .validator:
			roundedRectImage(placeholder: AssetResource.iconValidator)
		}
	}

	private func circularImage(placeholder: ImageAsset, placeholderBackground: Bool = false) -> some View {
		baseImage(placeholder: placeholder, placeholderBackground: placeholderBackground)
			.clipShape(Circle())
			.frame(size)
	}

	private func roundedRectImage(placeholder: ImageAsset, placeholderBackground: Bool = false) -> some View {
		baseImage(placeholder: placeholder, placeholderBackground: placeholderBackground)
			.cornerRadius(size.cornerRadius)
			.frame(size)
	}

	private func baseImage(placeholder: ImageAsset, placeholderBackground: Bool) -> some View {
		LoadableImage(url: url, size: .fixedSize(size)) {
			ZStack {
				if placeholderBackground {
					Rectangle()
						.fill(.app.gray4)
						.frame(size)
					Image(asset: placeholder)
						.resizable()
						.frame(width: size.rawValue * 0.75, height: size.rawValue * 0.75)
				} else {
					Image(asset: placeholder)
						.resizable()
				}
			}
		}
	}
}

// MARK: - LoadableImage
/// A helper view that handles the loading state, and potentially the error state
public struct LoadableImage<Placeholder: View>: View {
	let url: URL?
	let sizingBehaviour: LoadableImageSize
	let placeholderBehaviour: LoadableImagePlaceholderBehaviour
	let placeholder: Placeholder

	public init(
		url: URL?,
		size sizingBehaviour: LoadableImageSize,
		placeholders placeholderBehaviour: LoadableImagePlaceholderBehaviour = .default,
		placeholder: () -> Placeholder
	) {
		if let url {
			if url.isVectorImage {
				loggerGlobal.warning("LoadableImage: Vector images are not supported \(url)")
				self.url = nil
			} else {
				@Dependency(\.urlFormatterClient) var urlFormatterClient
				switch sizingBehaviour {
				case let .fixedSize(hitTargetSize, _):
					self.url = urlFormatterClient.fixedSizeImage(url, Screen.pixelScale * hitTargetSize.frame)
				case .flexible:
					self.url = urlFormatterClient.generalImage(url)
				}
			}
		} else {
			self.url = url
		}

		self.sizingBehaviour = sizingBehaviour
		self.placeholderBehaviour = placeholderBehaviour
		self.placeholder = placeholder()
	}

	public init(
		url: URL,
		size sizingBehaviour: LoadableImageSize,
		placeholders placeholderBehaviour: LoadableImagePlaceholderBehaviour = .default
	) where Placeholder == EmptyView {
		self.init(url: url, size: sizingBehaviour, placeholders: placeholderBehaviour) {
			EmptyView()
		}
	}

	public var body: some View {
		if let url {
			LazyImage(url: url) { state in
				if state.isLoading {
					loadingView
				} else if let image = state.image {
					imageView(image: image, imageSize: state.imageContainer?.image.size)
				} else {
					brokenImageView
					let _ = loggerGlobal.warning("Could not load thumbnail from \(url): \(state.error)")
				}
			}
		} else {
			placeholder
		}
	}

	@MainActor
	@ViewBuilder
	private func imageView(image: NukeUI.Image, imageSize: CGSize?) -> some View {
		switch sizingBehaviour {
		case let .fixedSize(size, mode):
			image
				.resizingMode(mode)
				.frame(width: size.frame.width, height: size.frame.height)
		case let .flexible(minAspect, maxAspect):
			if let imageSize {
				let aspect = min(maxAspect, max(imageSize.width / imageSize.height, minAspect))
				image
					.resizingMode(.aspectFill)
					.aspectRatio(aspect, contentMode: .fill)
			} else {
				image
					.scaledToFill()
			}
		}
	}

	@ViewBuilder
	private var loadingView: some View {
		switch placeholderBehaviour.loading {
		case .shimmer:
			Color.gray
				.shimmer(active: true, config: .accountResourcesLoading)

		case let .color(color):
			color
		case let .asset(imageAsset):
			Image(asset: imageAsset)
				.resizable()
		case .standard:
			placeholder
		}
	}

	@MainActor
	@ViewBuilder
	private var brokenImageView: some View {
		switch placeholderBehaviour.brokenImage {
		case let .asset(imageAsset):
			Image(asset: imageAsset)
				.resizable()
				.frame(width: brokenImageSize.width, height: brokenImageSize.height)
		case .brokenImage:
			HStack(spacing: 0) {
				Spacer(minLength: .small2)

				Image(asset: AssetResource.brokenImagePlaceholder)
					.resizable()
					.aspectRatio(1, contentMode: .fit)
					.frame(minWidth: .medium2, minHeight: .medium2)
					.frame(maxWidth: .large1, maxHeight: .large1)

				Spacer(minLength: .small2)
			}
			.frame(width: brokenImageSize.width, height: brokenImageSize.height)
			.background(.app.gray4)
		case .standard:
			placeholder
				.frame(width: brokenImageSize.width, height: brokenImageSize.height)
		}
	}

	private var brokenImageSize: (width: CGFloat?, height: CGFloat) {
		switch sizingBehaviour {
		case let .fixedSize(size, _):
			(size.frame.width, size.frame.height)
		case .flexible:
			(nil, .imagePlaceholderHeight)
		}
	}
}

// MARK: - LoadableImageSize
public enum LoadableImageSize: Equatable {
	case fixedSize(HitTargetSize, mode: ImageResizingMode = .aspectFill)
	case flexible(minAspect: CGFloat, maxAspect: CGFloat)
}

// MARK: - LoadableImagePlaceholderBehaviour
public struct LoadableImagePlaceholderBehaviour {
	public let loading: LoadingPlaceholder
	public let brokenImage: BrokenImagePlaceholder

	public static let `default`: Self = .init()

	/// `standard` refers to the placeholder supplied when creating the `LoadableImage`
	public init(loading: LoadingPlaceholder = .color(.clear), brokenImage: BrokenImagePlaceholder = .brokenImage) {
		self.loading = loading
		self.brokenImage = brokenImage
	}

	public enum LoadingPlaceholder {
		case shimmer
		case color(Color)
		case asset(ImageAsset)
		case standard
	}

	public enum BrokenImagePlaceholder {
		case asset(ImageAsset)
		case brokenImage
		case standard
	}
}

extension URL {
	public var isVectorImage: Bool {
		let pathComponent = lastPathComponent.lowercased()
		for ignoredType in URL.vectorImageTypes {
			if pathComponent.hasSuffix("." + ignoredType) {
				return true
			}
		}

		return false
	}

	private static let vectorImageTypes: [String] = ["svg", "pdf"]
}
