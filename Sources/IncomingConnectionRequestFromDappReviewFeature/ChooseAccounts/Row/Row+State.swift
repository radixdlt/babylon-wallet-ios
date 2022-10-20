import Foundation
import Address
import Profile

public extension ChooseAccounts.Row {
    struct State: Equatable {
        public let account: Profile.Account
        public var isSelected: Bool
        
        public init(
            account: Profile.Account,
            isSelected: Bool = false
        ) {
            self.account = account
            self.isSelected = isSelected
        }
    }
}

// MARK: - ChooseAccounts.Row.State + Identifiable
extension ChooseAccounts.Row.State: Identifiable {
    public typealias ID = Address
    public var id: Address { account.address }
}

#if DEBUG
public extension ChooseAccounts.Row.State {
    static let placeholder: Self = .init(
        account: .init(
            address: .random,
            name: "My account"
        ),
        isSelected: false
    )
}
#endif
