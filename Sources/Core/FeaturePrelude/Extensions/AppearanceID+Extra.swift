import DesignSystem
import SharedModels
import SwiftUI

extension Profile.Network.Account.AppearanceID {
	public var gradient: LinearGradient {
		.init(self)
	}
}

extension LinearGradient {
	public init(_ accountAppearanceID: Profile.Network.Account.AppearanceID) {
		self.init(gradient: .init(accountAppearanceID), startPoint: .leading, endPoint: .trailing)
	}
}

extension Gradient {
	public init(_ accountAppearanceID: Profile.Network.Account.AppearanceID) {
		self.init(accountNumber: accountAppearanceID.rawValue)
	}
}
