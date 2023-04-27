import ImageServiceClient
import NukeUI
import Prelude
import Resources
import SwiftUI

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
			LoadableImage(url: url, size: .fixed(size)) {
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
			LoadableImage(url: url, size: .fixed(size), mode: .aspectFill) {
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
		LoadableImage(url: url, size: .fixed(size)) {
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
		LoadableImage(url: content, size: .fixed(size)) {
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
	let size: LoadableImageSize
	let mode: ImageResizingMode
	let placeholder: Placeholder

	public init(url: URL?, size: LoadableImageSize, mode: ImageResizingMode = .aspectFill, placeholder: () -> Placeholder) {
		if let url {
			@Dependency(\.imageServiceClient) var imageServiceClient
			switch size {
			case let .fixed(hitTargetSize):
				self.url = imageServiceClient.fixedSize(url, hitTargetSize.frame)
				print(self.url)
			case .flexibleHeight:
				self.url = url
			}
		} else {
			self.url = nil
		}

		self.size = size
		self.mode = mode
		self.placeholder = placeholder()
	}

	public var body: some View {
		if let url {
			LazyImage(url: url) { state in
				if let image = state.image {
//					if flexHeight, let size = state.imageContainer?.image.size {
//						image.resizingMode(mode)
//							.aspectRatio(size.height / size.width, contentMode: .fill)
//					} else {
					image.resizingMode(mode)
//					}
				} else {
					if let error = state.error {
						let _ = loggerGlobal.warning("Could not load thumbnail \(url): \(error)")
					}
					placeholder
						.shimmer(active: state.isLoading, config: .accountResourcesLoading)
				}
			}
		} else {
			placeholder
		}
	}
}

// MARK: - LoadableImageSize
public enum LoadableImageSize {
	case fixed(HitTargetSize)
	case flexibleHeight
}
