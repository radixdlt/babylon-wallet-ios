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
			// TODO: Show different icon if known
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
			LoadableImage(url: url, size: .fixedSize(size)) {
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
		LoadableImage(url: url, size: .fixedSize(size), loading: .color(.app.gray1)) {
			Image(asset: AssetResource.nft)
				.resizable()
		}
		.cornerRadius(size.cornerRadius)
		.frame(size)
	}
}

// MARK: - PersonaThumbnail
public struct PersonaThumbnail: View {
	private let content: URL?
	private let size: HitTargetSize

	public init(_ content: URL?, size hitTargetSize: HitTargetSize = .small) {
		self.content = content
		self.size = hitTargetSize
	}

	public var body: some View {
		LoadableImage(url: content, size: .fixedSize(size)) {
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
	let loadingBehaviour: LoadableImageLoadingBehaviour
	let placeholder: Placeholder

	public init(
		url: URL?,
		size sizingBehaviour: LoadableImageSize,
		loading loadingBehaviour: LoadableImageLoadingBehaviour = .placeholder,
		placeholder: () -> Placeholder
	) {
		if let url {
			@Dependency(\.urlFormatterClient) var urlFormatterClient
			switch sizingBehaviour {
			case let .fixedSize(hitTargetSize, _):
				self.url = urlFormatterClient.fixedSizeImage(url, UIScreen.pixelScale * hitTargetSize.frame)
			case .flexibleHeight:
				self.url = url
			}
		} else {
			self.url = nil
		}

		self.sizingBehaviour = sizingBehaviour
		self.loadingBehaviour = loadingBehaviour
		self.placeholder = placeholder()
	}

	public var body: some View {
		if let url {
			LazyImage(url: url) { state in
				if state.isLoading {
					loadingView
				} else if let image = state.image {
					imageView(image: image, imageSize: state.imageContainer?.image.size)
				} else {
					if let error = state.error {
						let _ = loggerGlobal.warning("Could not load thumbnail \(url): \(error)")
					}
					placeholder
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
		case .flexibleHeight:
			if let imageSize {
				let minAspect: CGFloat = 9 / 16
				let aspect: CGFloat = imageSize.width / imageSize.height
				image
					.resizingMode(.aspectFill)
					.aspectRatio(max(aspect, minAspect), contentMode: .fill)
			} else {
				image
					.scaledToFill()
			}
		}
	}

	@ViewBuilder
	private var loadingView: some View {
		switch loadingBehaviour {
		case .shimmer:
			Color.gray
				.shimmer(active: true, config: .accountResourcesLoading)
		case let .color(color):
			color
		case let .asset(imageAsset):
			Image(asset: imageAsset)
				.resizable()
		case .placeholder:
			placeholder
		}
	}
}

// MARK: - LoadableImageSize
public enum LoadableImageSize {
	case fixedSize(HitTargetSize, mode: ImageResizingMode = .aspectFill)
	case flexibleHeight
}

// MARK: - LoadableImageLoadingBehaviour
public enum LoadableImageLoadingBehaviour {
	case shimmer
	case color(Color)
	case asset(ImageAsset)
	case placeholder
}
