import DesignSystem
import SharedModels
import SwiftUI

extension OnNetwork.Account.AppearanceID {
	public var gradient: LinearGradient {
		switch self {
		case ._0:
			return .app.account0
		case ._1:
			return .app.account1
		case ._2:
			return .app.account2
		case ._3:
			return .app.account3
		case ._4:
			return .app.account4
		case ._5:
			return .app.account5
		case ._6:
			return .app.account6
		case ._7:
			return .app.account7
		case ._8:
			return .app.account8
		case ._9:
			return .app.account9
		case ._10:
			return .app.account10
		case ._11:
			return .app.account11
		}
	}
}
