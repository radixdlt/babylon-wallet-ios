import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️

// MARK: - DappInteractionClient + DependencyKey
extension DappInteractionClient: DependencyKey {
	public static var liveValue: DappInteractionClient = {
		let interactionsSubject: AsyncPassthroughSubject<Result<ValidatedDappRequest, Error>> = .init()
		let interactionResponsesSubject: AsyncPassthroughSubject<P2P.RTCOutgoingMessage.Response> = .init()

		@Dependency(\.radixConnectClient) var radixConnectClient

		Task {
			_ = await radixConnectClient.loadP2PLinksAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}
				await interactionsSubject.send(validate(incomingRequest))
			}
		}

		return .init(
			interactions: interactionsSubject.share().eraseToAnyAsyncSequence(),
			addWalletInteraction: { items, interaction in
				@Dependency(\.gatewaysClient) var gatewaysClient

				let interactionId: WalletInteractionId = .walletInteractionID(for: interaction)

				let request = await ValidatedDappRequest(
					route: .wallet,
					request: .valid(
						.init(
							interactionId: interactionId,
							items: items,
							metadata: .init(
								version: .current,
								networkId: gatewaysClient.getCurrentNetworkID(),
								origin: .wallet,
								dappDefinitionAddress: .wallet
							)
						)
					),
					requiresOriginVerification: false
				)

				interactionsSubject.send(.success(request))

				return await interactionResponsesSubject.first(where: {
					switch $0 {
					case let .dapp(response):
						response.interactionId == interactionId
					}
				})
			},
			completeInteraction: { message in
				switch message {
				case let .response(response, route):
					interactionResponsesSubject.send(response)
					try await radixConnectClient.sendResponse(response, route)
				default:
					break
				}
			}
		)
	}()
}

extension DappInteractionClient {
	/// Validates a received request from Dapp.
	static func validate(
		_ message: P2P.RTCIncomingMessageContainer<DappToWalletInteractionUnvalidated>
	) async -> Result<ValidatedDappRequest, Error> {
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.rolaClient) var rolaClient

		let route = message.route

		let nonValidated: DappToWalletInteractionUnvalidated

		do {
			nonValidated = try message.result.get()
		} catch {
			return .failure(error)
		}

		func invalidRequest(_ reason: ValidatedDappRequest.InvalidRequestReason) -> Result<ValidatedDappRequest, Error> {
			.success(.init(route: route, request: .invalid(request: nonValidated, reason: reason), requiresOriginVerification: message.originRequiresValidation))
		}

		let nonvalidatedMeta = nonValidated.metadata
		guard WalletInteractionVersion.current == nonvalidatedMeta.version else {
			return invalidRequest(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: .current))
		}
		let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
		guard currentNetworkID == nonValidated.metadata.networkId else {
			return invalidRequest(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
		}

		let dappDefinitionAddress: DappDefinitionAddress
		do {
			dappDefinitionAddress = try DappDefinitionAddress(
				validatingAddress: nonValidated.metadata.dappDefinitionAddress
			)
		} catch {
			return invalidRequest(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dappDefinitionAddress))
		}

		switch nonValidated.items {
		case let .authorizedRequest(authorized):
			if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
				return invalidRequest(.badContent(.numberOfAccountsInvalid))
			}
			if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
				return invalidRequest(.badContent(.numberOfAccountsInvalid))
			}

		case let .unauthorizedRequest(unauthorized):
			if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
				return invalidRequest(.badContent(.numberOfAccountsInvalid))
			}
			if let proofOfOwnership = unauthorized.proofOfOwnership, await !proofOfOwnership.isValid() {
				return invalidRequest(.invalidPersonaOrAccounts)
			}

		default:
			break
		}

		let metadataValidDappDefAddress = DappToWalletInteractionMetadata(
			version: nonvalidatedMeta.version,
			networkId: nonvalidatedMeta.networkId,
			origin: nonvalidatedMeta.origin,
			dappDefinitionAddress: dappDefinitionAddress
		)

		let isDeveloperModeEnabled = await appPreferencesClient.isDeveloperModeEnabled()
		if !isDeveloperModeEnabled {
			do {
				try await rolaClient.performDappDefinitionVerification(metadataValidDappDefAddress)
				try await rolaClient.performWellKnownFileCheck(
					metadataValidDappDefAddress.origin.url(),
					metadataValidDappDefAddress.dappDefinitionAddress
				)
			} catch {
				loggerGlobal.warning("\(error)")
				return invalidRequest(.dAppValidationError(error.localizedDescription))
			}
		}

		return .success(
			.init(
				route: route,
				request: .valid(.init(
					interactionId: nonValidated.interactionId,
					items: nonValidated.items,
					metadata: metadataValidDappDefAddress
				)),
				requiresOriginVerification: message.originRequiresValidation
			)
		)
	}
}

extension DappToWalletInteractionProofOfOwnershipRequestItem {
	func isValid() async -> Bool {
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.accountsClient) var accountsClient
		do {
			if let identityAddress {
				// If there is an identityAddress set, verify we can access its corresponding Persona
				let _ = try await personasClient.getPersona(id: identityAddress)
			}
			if let accountAddresses {
				// For every accountAddress set, verify we can access its corresponding Account
				let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
				let accounts = allAccounts.filter {
					accountAddresses.contains($0.address)
				}
				if accounts.count != accountAddresses.count {
					return false
				}
			}
		} catch {
			return false
		}

		return true
	}
}
