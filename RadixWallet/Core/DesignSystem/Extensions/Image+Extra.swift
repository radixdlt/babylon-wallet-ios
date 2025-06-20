import SwiftUI

// MARK: - ImageSource
enum ImageSource {
	case imageResource(ImageResource)
	case sytemImage(String)
}

extension Image {
	init(source: ImageSource) {
		switch source {
		case let .imageResource(imageResource):
			self = .init(imageResource)
		case let .sytemImage(name):
			self = .init(systemName: name)
		}
	}
}
