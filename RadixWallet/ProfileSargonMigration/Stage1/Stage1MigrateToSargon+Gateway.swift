import Foundation
import Sargon

extension Gateway {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"network": network,
				"url": url,
			],
			displayStyle: .struct
		)
	}
}
