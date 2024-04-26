import Foundation
import Sargon

extension DepositAddressExceptionRule: CaseIterable {
	public static var allCases: [DepositAddressExceptionRule] {
		[.allow, .deny]
	}
}
