import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️

// MARK: - DappInteractionClient + DependencyKey
extension DappInteractionClient: DependencyKey {
	public static var liveValue: DappInteractionClient = {
		let interactionsSubject: AsyncPassthroughSubject<Result<ValidatedDappRequest, Error>> = .init()
		let interactionResponsesSubject: AsyncPassthroughSubject<P2P.RTCOutgoingMessage.Response> = .init()

		@Dependency(\.radixConnectClient) var radixConnectClient

		Task {
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

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

				let id: P2P.Dapp.Request.ID = .walletInteractionID(for: interaction)

				let request = await ValidatedDappRequest(
					route: .wallet,
					request: .valid(
						.init(
							id: id,
							items: items,
							metadata: .init(
								version: P2P.Dapp.currentVersion,
								networkId: gatewaysClient.getCurrentNetworkID(),
								origin: DappOrigin.wallet,
								dAppDefinitionAddress: .wallet
							)
						))
				)

				interactionsSubject.send(.success(request))

				return await interactionResponsesSubject.first(where: {
					switch $0 {
					case let .dapp(response):
						response.id == id
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
		_ message: P2P.RTCIncomingMessageContainer<P2P.Dapp.RequestUnvalidated>
	) async -> Result<ValidatedDappRequest, Error> {
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.rolaClient) var rolaClient

		let route = message.route

		let nonValidated: P2P.Dapp.RequestUnvalidated

		do {
			nonValidated = try message.result.get()
		} catch {
			return .failure(error)
		}

		func invalidRequest(_ reason: ValidatedDappRequest.InvalidRequestReason) -> Result<ValidatedDappRequest, Error> {
			.success(.init(route: route, request: .invalid(request: nonValidated, reason: reason)))
		}

		let nonvalidatedMeta = nonValidated.metadata
		guard P2P.Dapp.currentVersion == nonvalidatedMeta.version else {
			return invalidRequest(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: P2P.Dapp.currentVersion))
		}
		let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
		guard currentNetworkID == nonValidated.metadata.networkId else {
			return invalidRequest(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
		}

		let dappDefinitionAddress: DappDefinitionAddress
		do {
			dappDefinitionAddress = try DappDefinitionAddress(
				validatingAddress: nonValidated.metadata.dAppDefinitionAddress
			)
		} catch {
			return invalidRequest(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dAppDefinitionAddress))
		}

		if case let .request(readRequest) = nonValidated.items {
			switch readRequest {
			case let .authorized(authorized):
				if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
				if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
			case let .unauthorized(unauthorized):
				if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
			}
		}

		guard let origin = try? DappOrigin(string: nonvalidatedMeta.origin) else {
			return invalidRequest(.invalidOrigin(invalidURLString: nonvalidatedMeta.origin))
		}

		let metadataValidDappDefAddress = P2P.Dapp.Request.Metadata(
			version: nonvalidatedMeta.version,
			networkId: nonvalidatedMeta.networkId,
			origin: origin,
			dAppDefinitionAddress: dappDefinitionAddress
		)

		let isDeveloperModeEnabled = await appPreferencesClient.isDeveloperModeEnabled()
		if !isDeveloperModeEnabled {
			do {
				try await rolaClient.performDappDefinitionVerification(metadataValidDappDefAddress)
				try await rolaClient.performWellKnownFileCheck(metadataValidDappDefAddress)
			} catch {
				loggerGlobal.warning("\(error)")
				return invalidRequest(.dAppValidationError(error.localizedDescription))
			}
		}

		return .success(
			.init(
				route: route,
				request: .valid(.init(
					id: nonValidated.id,
					items: nonValidated.items,
					metadata: metadataValidDappDefAddress
				))
			)
		)
	}
}
