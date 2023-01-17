import ClientPrelude
import struct Profile.AccountAddress // FIXME: should probably be in ProfileModels so we can remove this import altogether

public typealias AccountPortfolioDictionary = [AccountAddress: AccountPortfolio]
