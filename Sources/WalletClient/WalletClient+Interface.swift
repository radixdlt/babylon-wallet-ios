import Profile

// MARK: - WalletClient
public struct WalletClient {
    public var injectProfile: InjectProfile
    public var getAccounts: GetAccounts
    
    public init(
        injectProfile: @escaping InjectProfile,
        getAccounts: @escaping GetAccounts
    ) {
        self.injectProfile = injectProfile
        self.getAccounts = getAccounts
    }
}

public extension WalletClient {
    typealias InjectProfile = @Sendable (Profile) throws -> Void
    typealias GetAccounts = @Sendable () -> [OnNetwork.Account]
}

public extension WalletClient {
    static func mock() -> Self {
        Self(
            injectProfile: { _ in /* No op */ },
            getAccounts: {
                [
                    OnNetwork.Account(
                        address: OnNetwork.Account.EntityAddress.init(address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"),
                        securityState: .unsecured(.ini),
                        index: <#T##OnNetwork.Account.Index#>,
                        derivationPath: <#T##OnNetwork.Account.EntityDerivationPath#>,
                        displayName: <#T##String?#>
                    )
                ]
            }
        )
    }
}
