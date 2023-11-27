// MARK: - FactorSourcesClient + DependencyKey
extension FactorSourcesClient: DependencyKey {
	public typealias Value = FactorSourcesClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let getFactorSources: GetFactorSources = {
			await profileStore.profile.factorSources
		}

		let saveFactorSource: SaveFactorSource = { source in
			try await profileStore.updating { profile in
				guard !profile.factorSources.contains(where: { $0.id == source.id }) else {
					throw FactorSourceAlreadyPresent()
				}
				profile.factorSources.append(source)
			}
		}

		let updateFactorSource: UpdateFactorSource = { source in
			try await profileStore.updating { profile in
				try profile.factorSources.updateFactorSource(id: source.id) {
					$0 = source
				}
			}
		}

		let addPrivateHDFactorSource: AddPrivateHDFactorSource = { request in
			let factorSource = request.factorSource

			switch factorSource {
			case let .device(deviceFactorSource):
				try secureStorageClient.saveMnemonicForFactorSource(.init(mnemonicWithPassphrase: request.mnemonicWithPasshprase, factorSource: deviceFactorSource))
			default:
				loggerGlobal.notice("Saving of non device private HD factor source not permitted, kind is: \(factorSource.kind)")
			}
			let factorSourceID = factorSource.id

			/// We only need to save olympia mnemonics into Profile, the Babylon ones
			/// already exist in profile, and this function is used only to save the
			/// imported mnemonic into keychain (done above).
			if request.saveIntoProfile {
				do {
					try await saveFactorSource(factorSource)
				} catch {
					loggerGlobal.critical("Failed to save factor source, error: \(error)")
					if let idForMnemonicToDelete = try? factorSourceID.extract(as: FactorSourceID.FromHash.self) {
						// We were unlucky, failed to update Profile, thus best to undo the saving of
						// the mnemonic in keychain (if we can).
						try? secureStorageClient.deleteMnemonicByFactorSourceID(idForMnemonicToDelete)
					}
					throw error
				}
			}

			return factorSourceID
		}

		let getMainDeviceFactorSource: GetMainDeviceFactorSource = {
			let sources = try await getFactorSources()
				.filter { $0.factorSourceKind == .device && !$0.supportsOlympia }
				.map { try $0.extract(as: DeviceFactorSource.self) }

			if let explicitMain = sources.first(where: { $0.isExplicitMain }) {
				return explicitMain
			} else {
				if sources.count == 0 {
					let errorMessage = "BAD IMPL found no babylon device factor source"
					loggerGlobal.critical(.init(stringLiteral: errorMessage))
					assertionFailure(errorMessage)
					throw FactorSourceNotFound()
				} else if sources.count > 1 {
					let errorMessage = "BAD IMPL found more than 1 implicit main babylon device factor sources"
					loggerGlobal.critical(.init(stringLiteral: errorMessage))
					assertionFailure(errorMessage)
					let dateSorted = sources.sorted(by: { $0.addedOn < $1.addedOn })
					return dateSorted.first! // best we can do
				} else {
					return sources[0] // found implicit one
				}
			}
		}

		let getCurrentNetworkID: GetCurrentNetworkID = {
			await profileStore.profile.networkID
		}

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			getMainDeviceFactorSource: getMainDeviceFactorSource,
			createNewMainDeviceFactorSource: {
				@Dependency(\.uuid) var uuid
				@Dependency(\.date) var date
				@Dependency(\.device) var device
				@Dependency(\.mnemonicClient) var mnemonicClient

				let model = await device.model
				let name = await device.name

				let mnemonicWithPassphrase = try MnemonicWithPassphrase(
					mnemonic: mnemonicClient.generate(
						BIP39.WordCount.twentyFour,
						BIP39.Language.english
					)
				)

				loggerGlobal.info("Creating new main BDFS")
				let newBDFS = try DeviceFactorSource.babylon(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					model: .init(model),
					name: .init(name)
				)
				assert(newBDFS.isExplicitMainBDFS)

				loggerGlobal.info("Saving new main BDFS to Profile and Keychain")
				_ = try await addPrivateHDFactorSource(.init(
					factorSource: newBDFS.embed(),
					mnemonicWithPasshprase: mnemonicWithPassphrase,
					saveIntoProfile: false
				))

				return try PrivateHDFactorSource(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSource: newBDFS
				)

			},
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await profileStore.factorSourcesValues()
			},
			nextEntityIndexForFactorSource: { request in
				let mainBDFS = try await getMainDeviceFactorSource()
				let factorSourceID = request.factorSourceID ?? mainBDFS.factorSourceID.embed()

				let currentNetworkID = await getCurrentNetworkID()
				let networkID = request.networkID ?? currentNetworkID
				let network = try? await profileStore.profile.network(id: networkID)

				/// We CANNOT just use `entitiesControlledByFactorSource.count` since it is possible that
				/// some users from Radix Babylon Wallet version 1.0.0 created accounts not sarting at
				/// index `0` (since we had global indexing, shared by all FactorSources...), lets say that
				/// only one account is controlled by a FactorSource `X`, having index `1`, then if we were
				/// to used `entitiesControlledByFactorSource.count` for "next index" then that would be...
				/// the value `1` AGAIN! Which does not work. Instead we need to read out the last path
				/// component (index!) of the derivation paths of `entitiesControlledByFactorSource` and
				/// find the MAX value and +1 on that. This also ensures that we are NOT "gap filling",
				/// meaning that we do not want to use index `0` even if it was not used, where `1` was used, so
				/// next index should be `2`, not `0` (which was free). The rationale is that it would just be
				/// confusing and messy (for us not the least). Best to always increase. But it is important
				/// to know  AccountRecoveryScan SHOULD find these "gap entities"!
				func nextDerivationIndexForFactorSource(
					entitiesControlledByFactorSource: some Collection<some EntityProtocol>
				) -> HD.Path.Component.Child.Value {
					let indicesOfEntitiesControlledByAccount = entitiesControlledByFactorSource
						.compactMap { entity -> HD.Path.Component.Child.Value? in
							switch entity.securityState {
							case let .unsecured(unsecuredControl):
								let factorInstance = unsecuredControl.transactionSigning
								guard factorInstance.factorSourceID.embed() == factorSourceID else {
									return nil
								}
								return factorInstance.derivationPath.index
							}
						}
					guard let max = indicesOfEntitiesControlledByAccount.max() else { return 0 }
					let nextIndex = max + 1
					return nextIndex
				}

				if let network {
					switch request.entityKind {
					case .account:
						return nextDerivationIndexForFactorSource(
							entitiesControlledByFactorSource: network.accountsIncludingHidden()
						)
					case .identity:
						return nextDerivationIndexForFactorSource(
							entitiesControlledByFactorSource: network.personasIncludingHidden()
						)
					}
				} else {
					// First time this factor source is use on network `networkID`
					return 0
				}
			},
			addPrivateHDFactorSource: addPrivateHDFactorSource,
			checkIfHasOlympiaFactorSourceForAccounts: {
				wordCount,
					softwareAccounts -> FactorSourceID.FromHash? in
				guard softwareAccounts.allSatisfy({ $0.accountType == .software }) else {
					assertionFailure("Unexpectedly received hardware account, unable to verify.")
					return nil
				}
				do {
					// Might be empty, if it is, we will just return nil (for-loop below not run).
					let olympiaDeviceFactorSources: [DeviceFactorSource] = try await getFactorSources()
						.filter(\.supportsOlympia)
						.filter { $0.kind == .device }
						.compactMap {
							guard
								let deviceFactorSource = try? $0.extract(as: DeviceFactorSource.self),
								deviceFactorSource.hint.mnemonicWordCount == wordCount
							else {
								return nil
							}
							return deviceFactorSource
						}

					let factorSourceIDs = olympiaDeviceFactorSources.map(\.id)

					for factorSourceID in factorSourceIDs {
						guard
							let mnemonic = try secureStorageClient.loadMnemonic(
								factorSourceID: factorSourceID,
								purpose: .importOlympiaAccounts,
								notifyIfMissing: false
							)
						else {
							continue
						}
						guard (try? mnemonic.validatePublicKeys(of: softwareAccounts)) == true else {
							continue
						}
						// YES Managed to validate all software accounts against existing factor source
						loggerGlobal.debug("Existing factor source found for selected Olympia software accounts.")
						return factorSourceID
					}

					return nil // Did not find any Olympia `.device` factor sources
				} catch {
					loggerGlobal.warning("Failed to check if olympia factor source exists, error: \(error)")
					return nil // failed? to find any Olympia `.device` factor sources
				}
			},
			saveFactorSource: saveFactorSource,
			updateFactorSource: updateFactorSource,
			getSigningFactors: { request in
				assert(request.signers.allSatisfy { $0.networkID == request.networkID })
				return try await signingFactors(
					for: request.signers,
					from: getFactorSources().rawValue,
					signingPurpose: request.signingPurpose
				)
			},
			updateLastUsed: { request in

				_ = try await profileStore.updating { profile in
					var factorSources = profile.factorSources.rawValue
					for id in request.factorSourceIDs {
						guard var factorSource = factorSources[id: id] else {
							throw FactorSourceNotFound()
						}
						factorSource.common.lastUsedOn = request.lastUsedOn
						factorSources[id: id] = factorSource
					}
					profile.factorSources = .init(rawValue: factorSources)!
				}
			},
			flagFactorSourceForDeletion: { id in
				let factorSources = try await getFactorSources()
				guard var factorSource = factorSources.rawValue[id: id] else {
					throw FactorSourceNotFound()
				}
				factorSource.flag(.deletedByUser)
				try await updateFactorSource(factorSource)
			}
		)
	}

	public static let liveValue = Self.live()
}

func signingFactors(
	for entities: some Collection<EntityPotentiallyVirtual>,
	from allFactorSources: IdentifiedArrayOf<FactorSource>,
	signingPurpose: SigningPurpose
) throws -> SigningFactors {
	var signingFactors: [FactorSourceKind: IdentifiedArrayOf<SigningFactor>] = [:]

	for entity in entities {
		switch entity.securityState {
		case let .unsecured(unsecuredEntityControl):

			let factorInstance = switch signingPurpose {
			case .signAuth:
				unsecuredEntityControl.authenticationSigning ?? unsecuredEntityControl.transactionSigning
			case .signTransaction:
				unsecuredEntityControl.transactionSigning
			}

			let id = factorInstance.factorSourceID
			guard let factorSource = allFactorSources[id: id.embed()] else {
				assertionFailure("Bad! factor source not found")
				throw FactorSourceNotFound()
			}
			let signer = try Signer(factorInstanceRequiredToSign: factorInstance, entity: entity)
			let sigingFactor = SigningFactor(factorSource: factorSource, signer: signer)

			if var existingArray: IdentifiedArrayOf<SigningFactor> = signingFactors[factorSource.kind] {
				if var existingSigningFactor = existingArray[id: factorSource.id] {
					var signers = existingSigningFactor.signers.rawValue
					signers[id: signer.id] = signer // update copy of `signers`
					existingSigningFactor.signers = .init(rawValue: signers)! // write back `signers`
					existingArray[id: factorSource.id] = existingSigningFactor // write back to IdentifiedArray
				} else {
					existingArray[id: factorSource.id] = sigingFactor // write back to IdentifiedArray
				}
				signingFactors[factorSource.kind] = existingArray // write back to Dictionary
			} else {
				// trivial case,
				signingFactors[factorSource.kind] = .init(uniqueElements: [sigingFactor])
			}
		}
	}

	return SigningFactors(
		uniqueKeysWithValues: signingFactors.map { keyValuePair -> (key: FactorSourceKind, value: NonEmpty<Set<SigningFactor>>) in
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
		case .ledgerHQHardwareWallet: 0
		case .offDeviceMnemonic: 1
		case .securityQuestions: 2
		case .trustedContact: 3

		// we want to sign with device last, since it would allow for us to stop using
		// ephemeral notary and allow us to implement a AutoPurgingMnemonicCache which
		// deletes items after 1 sec, thus `device` must come last.
		case .device: .max
		}
	}
}
