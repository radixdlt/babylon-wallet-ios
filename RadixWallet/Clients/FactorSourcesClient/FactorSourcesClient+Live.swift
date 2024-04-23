import Sargon

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
				.filter { $0.id == factorSourceID.embed() }
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
						try await updateFactorSource(updated.embed())
					}
				} else {
					do {
						try await saveFactorSource(deviceFactorSource.embed())
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

		let getMainDeviceFactorSource: GetMainDeviceFactorSource = {
			let sources = try await getFactorSources()
				.filter { $0.factorSourceKind == .device }
				.filter { !$0.supportsOlympia }
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

		let indicesOfEntitiesControlledByFactorSource: IndicesOfEntitiesControlledByFactorSource = { request in

			let factorSourceID = request.factorSourceID
			guard let factorSource = try await getFactorSources().first(where: { $0.id == factorSourceID }) else { throw FailedToFindFactorSource() }

			let currentNetworkID = await getCurrentNetworkID()
			let networkID = request.networkID ?? currentNetworkID
			let network = try? await profileStore.profile.network(id: networkID)

			func nextDerivationIndexForFactorSource(
				entitiesControlledByFactorSource: some Collection<some EntityProtocol>
			) throws -> OrderedSet<HDPathValue> {
				let indicesOfEntitiesControlledByAccount = entitiesControlledByFactorSource
					.compactMap { entity -> HDPathValue? in
						switch entity.securityState {
						case let .unsecured(unsecuredControl):
							let factorInstance = unsecuredControl.transactionSigning
							guard factorInstance.factorSourceID.embed() == factorSourceID else {
								return nil
							}
							guard factorInstance.derivationPath.scheme == request.derivationPathScheme else {
								/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
								/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
								return nil
							}
							return factorInstance.derivationPath.nonHardenedIndex
						}
					}
				return try OrderedSet(validating: indicesOfEntitiesControlledByAccount)
			}

			let indices: OrderedSet<HDPathValue> = if let network {
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
						BIP39WordCount.twentyFour,
						BIP39Language.english
					), passphrase: ""
				)

				loggerGlobal.info("Creating new main BDFS")
				var newBDFS = DeviceFactorSource.babylon(mnemonicWithPassphrase: mnemonicWithPassphrase, isMain: true)
				newBDFS.hint.model = model
				newBDFS.hint.name = name
				assert(newBDFS.isExplicitMainBDFS)

				loggerGlobal.info("Saving new main BDFS to Keychain only, we will NOT save it into Profile just yet.")

				_ = try await addPrivateHDFactorSource(
					.init(
						privateHDFactorSource: .init(
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							factorSource: newBDFS
						),
						onMnemonicExistsStrategy: .abort,
						saveIntoProfile: false
					)
				)

				return PrivateHierarchicalDeterministicFactorSource(
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
				let factorSourceID = request.factorSourceID ?? mainBDFS.factorSourceID

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
				let indices = try await indicesOfEntitiesControlledByFactorSource(
					.init(
						entityKind: request.entityKind,
						factorSourceID: factorSourceID,
						derivationPathScheme: request.derivationPathScheme,
						networkID: request.networkID
					)
				).indices

				guard let max = indices.max() else { return 0 }
				let nextIndex = max + 1
				return nextIndex
			},
			addPrivateHDFactorSource: addPrivateHDFactorSource,
			checkIfHasOlympiaFactorSourceForAccounts: { _, _ -> FactorSourceIDFromHash? in
				/*
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
				 updated.common.cryptoParameters.append(.olympiaOnly)
				 try await updateFactorSource(updated.embed())
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
				 */
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			saveFactorSource: saveFactorSource,
			updateFactorSource: updateFactorSource,
			getSigningFactors: { request in
				assert(request.signers.allSatisfy { $0.networkID == request.networkID })
				return try await signingFactors(
					for: request.signers,
					from: getFactorSources().asIdentified(),
					signingPurpose: request.signingPurpose
				)
			},
			updateLastUsed: { request in
				_ = try await profileStore.updating { profile in
					var factorSources = profile.factorSources
					for id in request.factorSourceIDs {
						guard var factorSource = factorSources.get(id: id) else {
							throw FactorSourceNotFound()
						}
						factorSource.common.lastUsedOn = request.lastUsedOn
						let updated = factorSources.updateOrAppend(factorSource)
						assert(updated != nil)
					}
					profile.factorSources = factorSources
				}
			},
			flagFactorSourceForDeletion: { id in
				let factorSources = try await getFactorSources()
				guard var factorSource = factorSources.get(id: id) else {
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
	for entities: some Collection<AccountOrPersona>,
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
				signingFactors[factorSource.kind] = [sigingFactor].asIdentified()
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
		case .ledgerHqHardwareWallet: 0
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
