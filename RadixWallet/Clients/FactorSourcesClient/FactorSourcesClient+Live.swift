import Sargon

// MARK: - FactorSourcesClient + DependencyKey
extension FactorSourcesClient: DependencyKey {
	typealias Value = FactorSourcesClient

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let getFactorSources: GetFactorSources = {
			await profileStore.profile().factorSources.asIdentified()
		}

		let saveFactorSource: SaveFactorSource = { source in
			try await profileStore.updating { profile in
				var identifiedFactorSources = profile.factorSources.asIdentified()
				guard identifiedFactorSources[id: source.id] == nil else {
					throw FactorSourceAlreadyPresent()
				}
				identifiedFactorSources.append(source)
				guard let nonEmpty = identifiedFactorSources.nonEmptyElements else {
					assertionFailure("Expected factor sources to not be empty, aborting update.")
					return
				}
				profile.factorSources = nonEmpty.rawValue
			}
		}

		let updateFactorSource: UpdateFactorSource = { source in
			try await profileStore.updating { profile in
				var identifiedFactorSources = profile.factorSources.asIdentified()
				try identifiedFactorSources.updateFactorSource(id: source.id) {
					$0 = source
				}
				guard let nonEmpty = identifiedFactorSources.nonEmptyElements else {
					assertionFailure("Expected factor sources to not be empty, aborting update.")
					return
				}
				profile.factorSources = nonEmpty.rawValue
			}
		}

		let addPrivateHDFactorSource: AddPrivateHDFactorSource = { request in
			let privateHDFactorSource = request.privateHDFactorSource
			let deviceFactorSource = privateHDFactorSource.factorSource
			let factorSourceID = deviceFactorSource.id

			do {
				try secureStorageClient.saveMnemonicForFactorSource(privateHDFactorSource)
			} catch {
				if
					secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceID),
					request.onMnemonicExistsStrategy == .appendWithCryptoParamaters
				{
					loggerGlobal.notice("Failed to save mnemonic, since it already exists, so this was expected.")
				} else {
					loggerGlobal.error("Failed to save mnemonic, error: \(error)")
					throw error
				}
			}

			/// We only need to save olympia mnemonics into Profile, the Babylon ones
			/// already exist in profile, and this function is used only to save the
			/// imported mnemonic into keychain (done above).
			let deviceFactorSources = try await getFactorSources()
				.filter { $0.id == factorSourceID.asGeneral }
				.map { try $0.extract(as: DeviceFactorSource.self) }

			if request.saveIntoProfile {
				if let existingInProfile = deviceFactorSources.first {
					switch request.onMnemonicExistsStrategy {
					case .abort:
						throw FactorSourceAlreadyPresent()
					case .appendWithCryptoParamaters:
						var updated = existingInProfile
						let cryptoParamsToAdd = request.privateHDFactorSource.factorSource.common.cryptoParameters
						updated.common.cryptoParameters.append(cryptoParamsToAdd)
						loggerGlobal.notice("Appended crypto parameters \(cryptoParamsToAdd) to DeviceFactorSource.")
						try await updateFactorSource(updated.asGeneral)
					}
				} else {
					do {
						try await saveFactorSource(deviceFactorSource.asGeneral)
					} catch {
						loggerGlobal.critical("Failed to save factor source, error: \(error)")
						// We were unlucky, failed to update Profile, thus best to undo the saving of
						// the mnemonic in keychain (if we can).
						try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
						throw error
					}
				}
			}

			return factorSourceID
		}

		let getCurrentNetworkID: GetCurrentNetworkID = {
			await profileStore.profile().networkID
		}

		let indicesOfEntitiesControlledByFactorSource: IndicesOfEntitiesControlledByFactorSource = { request in
			let factorSourceID = request.factorSourceID
			guard let factorSource = try await getFactorSources().first(where: { $0.id == factorSourceID }) else { throw FailedToFindFactorSource() }

			let currentNetworkID = await getCurrentNetworkID()
			let networkID = request.networkID ?? currentNetworkID
			let network = try? await profileStore.profile().network(id: networkID)

			func nextDerivationIndexForFactorSource(
				entitiesControlledByFactorSource: some Collection<some EntityProtocol>
			) throws -> OrderedSet<HdPathComponent> {
				let indicesOfEntitiesControlledByAccount = entitiesControlledByFactorSource
					.compactMap { entity -> HdPathComponent? in
						entity.unsecuredControllingFactorInstance.flatMap { factorInstance -> HdPathComponent? in
							guard factorInstance.factorSourceID.asGeneral == factorSourceID else {
								return nil
							}
							guard factorInstance.derivationPath.scheme == request.derivationPathScheme else {
								/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
								/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
								return nil
							}
							return factorInstance.derivationPath.lastPathComponent
						}
					}
				return try OrderedSet(validating: indicesOfEntitiesControlledByAccount)
			}

			let indices: OrderedSet<HdPathComponent> = if let network {
				switch request.entityKind {
				case .account:
					try nextDerivationIndexForFactorSource(
						entitiesControlledByFactorSource: network.accountsIncludingHidden()
					)
				case .persona:
					try nextDerivationIndexForFactorSource(
						entitiesControlledByFactorSource: network.personasIncludingHidden()
					)
				}
			} else {
				[]
			}

			return IndicesUsedByFactorSource(
				indices: indices,
				factorSource: factorSource,
				currentNetworkID: networkID
			)
		}

		return Self(
			indicesOfEntitiesControlledByFactorSource: indicesOfEntitiesControlledByFactorSource,
			getCurrentNetworkID: getCurrentNetworkID,
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await profileStore.factorSourcesValues()
			},
			addPrivateHDFactorSource: addPrivateHDFactorSource,
			checkIfHasOlympiaFactorSourceForAccounts: { wordCount, softwareAccounts -> FactorSourceIDFromHash? in
				guard softwareAccounts.allSatisfy({ $0.accountType == .software }) else {
					assertionFailure("Unexpectedly received hardware account, unable to verify.")
					return nil
				}
				do {
					// Might be empty, if it is, we will just return nil (for-loop below will not run).
					let deviceFactorSources: [DeviceFactorSource] = try await getFactorSources()
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

					for deviceFactorSource in deviceFactorSources {
						let factorSourceID = deviceFactorSource.id
						guard
							let mnemonic = try secureStorageClient.loadMnemonic(
								factorSourceID: factorSourceID,
								notifyIfMissing: false
							)
						else {
							continue
						}
						guard (try? mnemonic.validatePublicKeys(of: softwareAccounts)) == true else {
							continue
						}

						if !deviceFactorSource.supportsOlympia {
							loggerGlobal.notice("Adding Olympia CryptoParameters to factor source which lacked it.")
							var updated = deviceFactorSource
							updated.common.cryptoParameters.append(
								.olympia
							)
							try await updateFactorSource(updated.asGeneral)
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
					from: getFactorSources(),
					signingPurpose: request.signingPurpose
				)
			},
			updateLastUsed: { request in
				_ = try await profileStore.updating { profile in
					var identifiedFactorSources = profile.factorSources.asIdentified()
					for id in request.factorSourceIDs {
						guard var factorSource = identifiedFactorSources[id: id] else {
							throw FactorSourceNotFound()
						}
						factorSource.common.lastUsedOn = request.lastUsedOn
						let updated = identifiedFactorSources.updateOrAppend(factorSource)
						assert(updated != nil)
					}
					guard let nonEmpty = identifiedFactorSources.nonEmptyElements else {
						assertionFailure("Expected factor sources to not be empty, aborting update.")
						return
					}
					profile.factorSources = nonEmpty.rawValue
				}
			},
			flagFactorSourceForDeletion: { id in
				let factorSources = try await getFactorSources()
				guard var factorSource = factorSources[id: id] else {
					throw FactorSourceNotFound()
				}
				factorSource.flag(.deletedByUser)
				try await updateFactorSource(factorSource)
			}
		)
	}

	static let liveValue = Self.live()
}

func signingFactors(
	for entities: some Collection<AccountOrPersona>,
	from allFactorSources: IdentifiedArrayOf<FactorSource>,
	signingPurpose: SigningPurpose
) throws -> SigningFactors {
	var signingFactors: [FactorSourceKind: IdentifiedArrayOf<SigningFactor>] = [:]

	for entity in entities {
		guard let factorInstance = entity.unsecuredControllingFactorInstance else {
			continue
		}

		let id = factorInstance.factorSourceID
		guard let factorSource = allFactorSources[id: id.asGeneral] else {
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
			signingFactors[factorSource.kind] = [sigingFactor].asIdentified()
		}
	}

	return try SigningFactors(
		keysWithValues: signingFactors.map { keyValuePair -> (key: FactorSourceKind, value: NonEmpty<Set<SigningFactor>>) in
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
		case .ledgerHqHardwareWallet: 0
		case .arculusCard: 1
		case .offDeviceMnemonic: 2
		case .password: 3
		// we want to sign with device last, since it would allow for us to stop using
		// ephemeral notary and allow us to implement a AutoPurgingMnemonicCache which
		// deletes items after 1 sec, thus `device` must come last.
		case .device: .max
		}
	}
}
