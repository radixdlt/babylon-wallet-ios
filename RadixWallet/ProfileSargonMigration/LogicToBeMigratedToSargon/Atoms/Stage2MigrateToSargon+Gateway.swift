import Foundation
import Sargon

extension Gateway {
	public var isWellknown: Bool {
		sargonProfileStage1()
	}
}
