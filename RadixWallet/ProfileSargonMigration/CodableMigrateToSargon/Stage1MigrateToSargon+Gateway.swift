import Foundation
import Sargon

// MARK: - Gateway + Identifiable
extension Gateway: Identifiable {
	public typealias ID = URL
	public var id: ID { url }
}

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

	public var description: String {
		"""
		network: \(network),
		url: \(url)
		"""
	}
}

extension Gateway {
	public static let `default` = Gateway.mainnet
}

extension Gateway {
	public static var mainnet: Self {
		sargonProfileStage1()
	}

	public static var stokenet: Self {
		sargonProfileStage1()
	}

	public static var rcnet: Self {
		sargonProfileStage1()
	}

	public static var nebunet: Self {
		sargonProfileStage1()
	}

	public static var kisharnet: Self {
		sargonProfileStage1()
	}

	public static var ansharnet: Self {
		sargonProfileStage1()
	}

	public static var hammunet: Self {
		sargonProfileStage1()
	}

	public static var enkinet: Self {
		sargonProfileStage1()
	}

	public static var mardunet: Self {
		sargonProfileStage1()
	}

	public static var simulator: Self {
		sargonProfileStage1()
	}
}
