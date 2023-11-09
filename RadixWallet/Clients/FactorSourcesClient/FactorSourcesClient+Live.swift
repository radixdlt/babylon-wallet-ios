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

		return Self(
			getCurrentNetworkID: {
				await profileStore.profile.networkID
			},
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await profileStore.factorSourcesValues()
			},
			addPrivateHDFactorSource: { request in
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
			},
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
