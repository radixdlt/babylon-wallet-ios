import SwiftUI

// MARK: - ImageSource
enum ImageSource: Hashable, Equatable, Sendable {
	case imageResource(ImageResource)
	case systemImage(String)
}

extension Image {
	init(source: ImageSource) {
		switch source {
		case let .imageResource(imageResource):
			self = .init(imageResource)
		case let .systemImage(name):
			self = .init(systemName: name)
		}
	}
}
