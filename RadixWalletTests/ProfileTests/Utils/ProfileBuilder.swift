import Foundation
@testable import Radix_Wallet_Dev

// MARK: - ProfileBuilder
public final class ProfileBuilder {
	private let profileID: ProfileSnapshot.Header.ID
	private var bdfs: PrivateHDFactorSource?
	private var networks: IdentifiedArrayOf<Network> = []

	public init(
		id: ProfileSnapshot.Header.ID? = nil
	) {
		self.profileID = id ?? UUID()
	}
}

extension ProfileBuilder {
	public func build() -> Profile {
		guard let bdfs else { fatalError("No BDFS, unable to create Profile.") }
		let deviceInfo = DeviceInfo(description: "Builder", id: UUID(), date: .now)
		let networksDictionary: OrderedDictionary<NetworkID, Profile.Network> = .init(uniqueKeysWithValues: self.networks.map {
			(key: $0.id, value: Profile.Network(networkID: $0.id, accounts: .init(rawValue: $0.accounts)!, personas: [], authorizedDapps: []))
		})
		assert(networksDictionary.keys.contains(.mainnet))
		let profile = Profile(
			header: .init(
				creatingDevice: deviceInfo,
				lastUsedOnDevice: deviceInfo,
				id: self.profileID,
				lastModified: .now,
				contentHint: .init(numberOfAccountsOnAllNetworksInTotal: self.networks.reduce(0) { $0 + $1.accounts.count })
			),
			deviceFactorSource: bdfs.factorSource,
			appPreferences: .init(gateways: .init(current: .mainnet)),
			networks: .init(dictionary: networksDictionary)
		)
		assert(!profile.network!.getAccounts().isEmpty)
		return profile
	}
}

// MARK: ProfileBuilder.Network
extension ProfileBuilder {
	private final class Network: Identifiable {
		let id: NetworkID
		var accounts: IdentifiedArrayOf<Profile.Network.Account>
		init(id: NetworkID, accounts: IdentifiedArrayOf<Profile.Network.Account> = []) {
			self.id = id
			self.accounts = accounts
		}

		func addAccount(_ account: Profile.Network.Account) {
			accounts.append(account)
		}
	}
}

extension ProfileBuilder {
	// TODO: Refactor to use real clients aligning with prod code?
	public func bdfs(_ maybeMnemonic: Mnemonic? = nil) -> Self {
		let mnemonic = try! maybeMnemonic ?? Mnemonic.generate(wordCount: .twentyFour, language: .english)
		let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: "")
		let date = Date.now
		let deviceFactorSource = try! DeviceFactorSource.babylon(mnemonicWithPassphrase: mnemonicWithPassphrase, addedOn: date, lastUsedOn: date)
		self.bdfs = try! PrivateHDFactorSource(mnemonicWithPassphrase: mnemonicWithPassphrase, factorSource: deviceFactorSource)
		return self
	}

	// TODO: Refactor to use real clients aligning with prod code?
	public func account(
		name: String = "Unnamed",
		network networkID: NetworkID = .mainnet
	) -> Self {
		guard let bdfs else { fatalError("No BDFS, unable to create account.") }
		let network = networks[id: networkID] ?? Network(id: networkID)
		let index = HD.Path.Component.Child.Value(network.accounts.count)

		let hdRoot = try! bdfs.mnemonicWithPassphrase.hdRoot()
		let derivationPath = try! AccountBabylonDerivationPath(networkID: networkID, index: index, keyKind: .transactionSigning)
		let key = try! hdRoot.derivePrivateKey(
			path: derivationPath.fullPath,
			curve: Curve25519.self
		)
		let factorInstance = HierarchicalDeterministicFactorInstance(id: bdfs.factorSource.id, publicKey: .eddsaEd25519(key.publicKey), derivationPath: derivationPath.wrapAsDerivationPath())
		let address = try! Profile.Network.Account.deriveVirtualAddress(
			networkID: networkID,
			factorInstance: factorInstance
		)
		let account = Profile.Network.Account(
			networkID: networkID,
			index: index,
			address: address,
			factorInstance: factorInstance,
			displayName: .init(rawValue: name)!,
			extraProperties: .init(appearanceID: ._0)
		)
		network.addAccount(account)
		self.networks[id: networkID] = network
		return self
	}
}
