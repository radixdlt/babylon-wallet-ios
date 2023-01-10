import Prelude

public extension FixedWidthInteger {
	var inAttos: BigUInt {
		BigUInt(self).inAttos
	}
}
