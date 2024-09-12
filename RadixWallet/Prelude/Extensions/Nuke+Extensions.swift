import Nuke

extension ImageDecoderRegistry {
	static func bootstrap() {
		ImageDecoderRegistry.shared.register { context in
			let isSVG = context.urlResponse?.url?.isVectorImage(type: .svg) ?? false
			return isSVG ? ImageDecoders.Empty() : nil
		}
	}
}
