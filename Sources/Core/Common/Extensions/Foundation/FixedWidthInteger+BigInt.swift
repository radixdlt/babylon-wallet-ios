import BigInt
import Foundation

public extension FixedWidthInteger {
	var inAttos: BigUInt {
		BigUInt(self).inAttos
	}
}
