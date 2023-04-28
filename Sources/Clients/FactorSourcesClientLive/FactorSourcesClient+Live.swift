import ClientPrelude
import FactorSourcesClient
import ProfileStore

// MARK: - FactorSourcesClient + DependencyKey
extension FactorSourcesClient: DependencyKey {
	public typealias Value = FactorSourcesClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let getFactorSources: GetFactorSources = {
			await getProfileStore().profile.factorSources
		}

		let addOffDeviceFactorSource: AddOffDeviceFactorSource = { source in
			try await getProfileStore().updating { profile in
				guard !profile.factorSources.contains(where: { $0.id == source.id }) else {
					throw FactorSourceAlreadyPresent()
				}
				profile.factorSources.append(source)
			}
		}

		return Self(
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await getProfileStore().factorSourcesValues()
			},
			addPrivateHDFactorSource: { privateFactorSource in

				try await secureStorageClient.saveMnemonicForFactorSource(privateFactorSource)
				let factorSourceID = privateFactorSource.hdOnDeviceFactorSource.factorSource.id
				do {
					try await addOffDeviceFactorSource(privateFactorSource.hdOnDeviceFactorSource.factorSource)
				} catch {
					// We were unlucky, failed to update Profile, thus best to undo the saving of
					// the mnemonic in keychain (if we can).
					try? await secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
					throw error
				}

				return factorSourceID
			},
			checkIfHasOlympiaFactorSourceForAccounts: { softwareAccounts in
				guard softwareAccounts.allSatisfy({ $0.accountType == .software }) else {
					assertionFailure("Unexpectedly received hardware account, unable to verify.")
					return nil
				}
				do {
					let factorSourceIDs = try await getFactorSources()
						.filter { $0.kind == .device && $0.supportsOlympia }
						.map(\.id)

					for factorSourceID in factorSourceIDs {
						guard let mnemonic = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .importOlympiaAccounts) else {
							continue
						}
						guard try mnemonic.validatePublicKeysOf(softwareAccounts: softwareAccounts) else {
							continue
						}
						// YES Managed to validate all software accounts against existing factor source
						loggerGlobal.debug("Existing factor source found for selected Olympia software accounts.")
						return factorSourceID
					}

					return nil // failed to find any factor source
				} catch {
					loggerGlobal.warning("Failed to check if olympia factor source exists, error: \(error)")
					return nil // failure
				}
			},
			addOffDeviceFactorSource: addOffDeviceFactorSource,
			getSigningFactors: { _, accounts in
				try await signingFactors(
					for: accounts,
					from: getFactorSources().rawValue
				)
			}
		)
	}

	public static let liveValue = Self.live()
}

internal func signingFactors(
	for accounts: some Collection<Profile.Network.Account>,
	from allFactorSources: IdentifiedArrayOf<FactorSource>
) throws -> SigningFactors {
	var signingFactors: [FactorSourceKind: NonEmpty<Set<SigningFactor>>] = [:]

	for account in accounts {
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			let factorInstance = unsecuredEntityControl.genesisFactorInstance
			let id = factorInstance.factorSourceID
			guard let factorSource = allFactorSources[id: id] else {
				assertionFailure("Bad! factor source not found")
				throw FactorSourceNotFound()
			}
			let signer = SigningFactor.Signer(account: account, factorInstancesRequiredToSign: [factorInstance])
			let sigingFactor = SigningFactor(factorSource: factorSource, signers: .init(rawValue: [signer])!)
			if let existing = signingFactors[factorSource.kind] {
				// Complex case, this factor source kind already present in the dictionary => update `NonEmpty<Set<SigningFactor>>`

				// we cannot mutate `rawValue` of `NonEmpty` :/ thus this complex dance
				var unorderedSet = existing.rawValue // read out `Set<SigningFactor>` (which is non empty)
				if var existingSigningFactorForThisFactorSource = unorderedSet.first(where: { $0.factorSource == factorSource }) {
					// The most complex case, set `unorderedSet` contains this factor source... must update the `SigningFactor`
					unorderedSet.remove(existingSigningFactorForThisFactorSource) // remove and dont forget to readd
					var signers = existingSigningFactorForThisFactorSource.signers.rawValue
					signers.insert(signer)
					existingSigningFactorForThisFactorSource.signers = .init(rawValue: signers)!
					unorderedSet.insert(existingSigningFactorForThisFactorSource) // dont forget to re-add the updated
				} else {
					// easy case
					unorderedSet.insert(sigingFactor)
				}

				// Dont forget to update the dictionary!
				signingFactors[factorSource.kind] = .init(rawValue: unorderedSet)!
			} else {
				// trivial case,
				signingFactors[factorSource.kind] = .init(rawValue: [sigingFactor])!
			}
		}
	}
	return .init(uniqueKeysWithValues: signingFactors.sorted(by: \.key))
}

// MARK: - FactorSourceNotFound
struct FactorSourceNotFound: Swift.Error {}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}

// MARK: - FactorSourceKind + Comparable
extension FactorSourceKind: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.signingOrder < rhs.signingOrder
	}

	fileprivate var signingOrder: Int {
		switch self {
		case .ledgerHQHardwareWallet: return 0
		case .device:
			// we want to sign with device last, since it would allow for us to stop using
			// ephemeral notary and allow us to implement a AutoPurgingMnemonicCache which
			// deletes items after 1 sec, thus `device` must come last.
			return 1
		}
	}
}
