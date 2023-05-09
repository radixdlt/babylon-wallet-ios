import Prelude

// MARK: - Radix.Dashboard
extension Radix {
	public struct Dashboard: Sendable, Hashable, Codable, Identifiable, CustomStringConvertible {
		public typealias ID = URL

		public let url: URL
		public var id: ID { url }

		public init(url: URL) {
			self.url = url
		}
	}
}

extension Radix.Dashboard {
	public static let `default` = rcnet
}

extension Radix.Dashboard {
	public static var rcnet: Self {
		.init(
			url: URL(string: "https://rcnet-dashboard.radixdlt.com/")!
		)
	}
}

extension Radix.Dashboard {
	public var description: String {
		"""
		url: \(url)
		"""
	}
}
