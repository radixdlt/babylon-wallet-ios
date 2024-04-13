import Foundation
import Sargon

public typealias HDPathValue = UInt32

public typealias BIP44LikePath = Bip44LikePath
extension BIP44LikePath {
	public var addressIndex: HDPathValue {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
