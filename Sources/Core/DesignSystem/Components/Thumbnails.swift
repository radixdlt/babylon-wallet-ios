import NukeUI
import Prelude
import Resources
import SwiftUI
import URLFormatterClient

// MARK: - DappThumbnail
public struct DappThumbnail: View {
	private let content: Content
	private let size: HitTargetSize

	public enum Content: Sendable, Hashable {
		case known(URL?)
		case unknown
	}

	public init(_ content: Content, size hitTargetSize: HitTargetSize = .small) {
		self.content = content
		self.size = hitTargetSize
	}

	public var body: some View {
		image
			.cornerRadius(size.cornerRadius)
			.frame(size)
	}

	@ViewBuilder
	@MainActor
	private var image: some View {
		switch content {
		case let .known(url):
			LoadableImage(url: url, size: .fixedSize(size)) {
				placeholder
			}
		case .unknown:
			// TODO: Show different icon if unknown
			placeholder
		}
	}

	private var placeholder: some View {
		Image(asset: AssetResource.unknownComponent)
			.resizable()
	}
}

// MARK: - TokenThumbnail
public struct TokenThumbnail: View {
	private let content: Content
	private let size: HitTargetSize

	public enum Content: Sendable, Hashable {
		case xrd
		case known(URL?)
		case unknown
	}

	public init(_ content: Content, size hitTargetSize: HitTargetSize = .small) {
		self.content = content
		self.size = hitTargetSize
	}

	public var body: some View {
		image
			.clipShape(Circle())
			.frame(size)
	}

	@ViewBuilder
	@MainActor
	private var image: some View {
		switch content {
		case .xrd:
			Image(asset: AssetResource.xrd)
				.resizable()
		case let .known(url):
			LoadableImage(url: url, size: .fixedSize(size), placeholders: .init(brokenImage: .standard)) {
				placeholder
			}
		case .unknown:
			// TODO: Show different icon if unknown?
			placeholder
		}
	}

	private var placeholder: some View {
		Image(asset: AssetResource.token)
			.resizable()
	}
}

// MARK: - NFTThumbnail
public struct NFTThumbnail: View {
	private let url: URL?
	private let size: HitTargetSize

	public init(_ url: URL?, size hitTargetSize: HitTargetSize = .small) {
		self.url = url
		self.size = hitTargetSize
	}

	public var body: some View {
		LoadableImage(url: url, size: .fixedSize(size), placeholders: .init(loading: .color(.app.gray1))) {
			Image(asset: AssetResource.nft)
				.resizable()
		}
		.cornerRadius(size.cornerRadius)
		.frame(size)
	}
}

// MARK: - PersonaThumbnail
public struct PersonaThumbnail: View {
	private let url: URL?
	private let size: HitTargetSize

	public init(_ url: URL?, size hitTargetSize: HitTargetSize = .small) {
		self.url = url
		self.size = hitTargetSize
	}

	public var body: some View {
		LoadableImage(url: url, size: .fixedSize(size)) {
			Image(asset: AssetResource.persona)
				.resizable()
		}
		.clipShape(Circle())
		.frame(size)
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
		if let url, !url.isVectorImage, case let .fixedSize(hitTargetSize, _) = sizingBehaviour {
			@Dependency(\.urlFormatterClient) var urlFormatterClient
			self.url = urlFormatterClient.fixedSizeImage(url, Screen.pixelScale * hitTargetSize.frame)
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
					if let error = state.error {
						if url.isVectorImage {
							let _ = loggerGlobal.warning("Could not load thumbnail \(url): \(error)")
						} else {
							let _ = loggerGlobal.warning("Vector images are not supported \(url): \(error)")
						}
					}
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
		case .brokenImage:
			VStack(spacing: 0) {
				Spacer(minLength: 0)

				HStack(spacing: 0) {
					Spacer(minLength: 0)

					Image(asset: AssetResource.brokenImagePlaceholder)

					Spacer(minLength: 0)
				}

				Spacer(minLength: 0)
			}
			.background(.app.gray4)
		case .standard:
			placeholder
		}
	}
}

// MARK: - LoadableImageSize
public enum LoadableImageSize: Equatable {
	case fixedSize(HitTargetSize, mode: ImageResizingMode = .aspectFill)
	case flexible(minAspect: CGFloat, maxAspect: CGFloat)

	var isFixedSize: Bool {
		if case .fixedSize = self { return true }
		return false
	}
}

// MARK: - LoadableImagePlaceholderBehaviour
public struct LoadableImagePlaceholderBehaviour {
	public let loading: LoadingPlaceholder
	public let brokenImage: BrokenImagePlaceholder

	public static let `default`: Self = .init()

	/// `standard` refers to the placeholder supplied when creating the `LoadableImage`
	public init(loading: LoadingPlaceholder = .standard, brokenImage: BrokenImagePlaceholder = .brokenImage) {
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
