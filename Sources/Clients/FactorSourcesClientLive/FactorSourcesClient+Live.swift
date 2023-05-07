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
			checkIfHasOlympiaFactorSourceForAccounts: { softwareAccounts -> FactorSourceID? in
				guard softwareAccounts.allSatisfy({ $0.accountType == .software }) else {
					assertionFailure("Unexpectedly received hardware account, unable to verify.")
					return nil
				}
				do {
					// cannot use `getFactorSources:ofKind`
					let factorSourceIDs = try await getFactorSources()
						.filter(\.supportsOlympia)
						.filter { $0.kind == .device }
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
			getSigningFactors: { networkID, entities in
				assert(entities.allSatisfy { $0.networkID == networkID })
				return try await signingFactors(
					for: entities,
					from: getFactorSources().rawValue
				)
			},
			updateLastUsed: { request in

				_ = try await getProfileStore().updating { profile in
					var factorSources = profile.factorSources.rawValue
					for id in request.factorSourceIDs {
						guard var factorSource = factorSources[id: id] else {
							throw FactorSourceNotFound()
						}

						factorSource.lastUsedOn = request.lastUsedOn
						factorSources[id: id] = factorSource
					}
					profile.factorSources = .init(rawValue: factorSources)!
				}
			}
		)
	}

	public static let liveValue = Self.live()
}

internal func signingFactors(
	for entities: some Collection<Signer.Entity>,
	from allFactorSources: IdentifiedArrayOf<FactorSource>
) throws -> SigningFactors {
	var signingFactorsNotNonEmpty: [FactorSourceKind: IdentifiedArrayOf<SigningFactor>] = [:]

	for entity in entities {
		switch entity.securityState {
		case let .unsecured(unsecuredEntityControl):
			let factorInstance = unsecuredEntityControl.transactionSigning
			let id = factorInstance.factorSourceID
			guard let factorSource = allFactorSources[id: id] else {
				assertionFailure("Bad! factor source not found")
				throw FactorSourceNotFound()
			}
			let signer = try Signer(factorInstanceRequiredToSign: factorInstance, entity: entity)
			let sigingFactor = SigningFactor(factorSource: factorSource, signer: signer)

			if var existingArray: IdentifiedArrayOf<SigningFactor> = signingFactorsNotNonEmpty[factorSource.kind] {
				if var existingSigningFactor = existingArray[id: factorSource.id] {
					var signers = existingSigningFactor.signers.rawValue
					signers[id: signer.id] = signer // update copy of `signers`
					existingSigningFactor.signers = .init(rawValue: signers)! // write back `signers`
					existingArray[id: factorSource.id] = existingSigningFactor // write back to IdentifiedArray
				} else {
					existingArray[id: factorSource.id] = sigingFactor // write back to IdentifiedArray
				}
				signingFactorsNotNonEmpty[factorSource.kind] = existingArray // write back to Dictionary
			} else {
				// trivial case,
				signingFactorsNotNonEmpty[factorSource.kind] = .init(uniqueElements: [sigingFactor])
			}
		}
	}

	return SigningFactors(
		uniqueKeysWithValues: signingFactorsNotNonEmpty.map { keyValuePair -> (key: FactorSourceKind, value: NonEmpty<Set<SigningFactor>>) in
			assert(!keyValuePair.value.isEmpty, "Incorrect implementation, IdentifiedArrayOf<SigningFactor> should never be empty.")
			let value: NonEmpty<Set<SigningFactor>> = .init(rawValue: Set(keyValuePair.value))!
			return (key: keyValuePair.key, value: value)
		}.sorted(by: \.key)
	)
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
