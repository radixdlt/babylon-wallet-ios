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

extension Gateway {
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
