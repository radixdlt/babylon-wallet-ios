import Foundation
import Sargon

extension AssetException {
	public func updateExceptionRule(_ rule: DepositAddressExceptionRule) -> Self {
		Self(address: address, exceptionRule: rule)
	}
}
