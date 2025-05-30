import Foundation
import Sargon

extension AssetException {
	func updateExceptionRule(_ rule: DepositAddressExceptionRule) -> Self {
		Self(address: address, exceptionRule: rule)
	}
}
