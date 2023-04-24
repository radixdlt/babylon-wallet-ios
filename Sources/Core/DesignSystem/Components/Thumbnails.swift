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
		case let .known(url?):
			LazyImage(url: url) { _ in
				placeholder.border(.red)
			}
		case .known(nil), .unknown:
			// TODO: Show different icon if known
			placeholder.border(.yellow)
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
		case let .known(url?):
			LazyImage(url: url) { _ in
				placeholder.border(.red)
			}

		// TODO: Show different icon if known
		case .known(nil), .unknown:
			placeholder.border(.yellow)
		}
	}

	private var placeholder: some View {
		Image(asset: AssetResource.token)
			.resizable()
	}
}

// MARK: - NFTThumbnail
public struct NFTThumbnail: View {
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
		case let .known(url?):
			LazyImage(url: url) { _ in
				placeholder.border(.red)
			}
		case .known(nil), .unknown:
			// TODO: Show different icon if known
			placeholder.border(.yellow)
		}
	}

	private var placeholder: some View {
		Image(asset: AssetResource.nft)
			.resizable()
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
		image
			.clipShape(Circle())
			.frame(size)
	}

	@ViewBuilder
	private var image: some View {
		if let content {
			Image(asset: AssetResource.persona)
				.resizable()
		} else {
			Image(asset: AssetResource.persona)
				.resizable()
		}
	}
}
