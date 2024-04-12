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
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var stokenet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var rcnet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var nebunet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var kisharnet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var ansharnet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var hammunet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var enkinet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var mardunet: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var simulator: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
