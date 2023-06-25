import CreateAuthKeyFeature
import EditPersonaFeature
import FeaturePrelude
import TransactionReviewFeature

// MARK: - View

extension PersonaDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<PersonaDetails>

		public init(store: StoreOf<PersonaDetails>) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let thumbnail: URL?
		let personaName: String
		let isDappPersona: Bool

		#if DEBUG
		public var canCreateAuthKey: Bool
		#endif // DEBUG
	}
}

// MARK: - Body

extension PersonaDetails.View {
	public var body: some View {
		ScrollView(showsIndicators: false) {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					PersonaThumbnail(viewStore.thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoSection(store: store.actionless)

					#if DEBUG
					VStack {
						Button("Create & Upload Auth Key") {
							viewStore.send(.createAndUploadAuthKeyButtonTapped)
						}
						.controlState(viewStore.canCreateAuthKey ? .enabled : .disabled)
						.buttonStyle(.secondaryRectangular)
					}
					.padding(.top, .large3)
					#endif

					Button(L10n.AuthorizedDapps.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					if viewStore.isDappPersona {
						IfLetStore(store.scope(state: \.accountSection, action: PersonaDetails.Action.view)) {
							AccountSection(store: $0)
								.background(.app.gray5)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.removeAuthorization) {
							viewStore.send(.deauthorizePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					} else {
						IfLetStore(store.scope(state: \.dAppsSection, action: PersonaDetails.Action.view)) {
							DappsSection(store: $0)
								.background(.app.gray5)
						}
					}
				}
				.navigationTitle(viewStore.personaName)
				#if os(iOS)
					.navigationBarTitleDisplayMode(.inline)
				#endif
					.onAppear {
						viewStore.send(.appeared)
					}
			}
		}
		.navigationDestination(
			store: store.destination,
			state: /PersonaDetails.Destination.State.dAppDetails,
			action: PersonaDetails.Destination.Action.dAppDetails,
			destination: { SimpleDappDetails.View(store: $0) }
		)
		.sheet(
			store: store.destination,
			state: /PersonaDetails.Destination.State.editPersona,
			action: PersonaDetails.Destination.Action.editPersona,
			content: { EditPersona.View(store: $0) }
		)
		.sheet(
			store: store.destination,
			state: /PersonaDetails.Destination.State.createAuthKey,
			action: PersonaDetails.Destination.Action.createAuthKey,
			content: { CreateAuthKey.View(store: $0) }
		)
		.alert(
			store: store.destination,
			state: /PersonaDetails.Destination.State.confirmForgetAlert,
			action: PersonaDetails.Destination.Action.confirmForgetAlert
		)
	}
}

private extension StoreOf<PersonaDetails> {
	var destination: PresentationStoreOf<PersonaDetails.Destination> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	#if DEBUG
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona,
			canCreateAuthKey: canCreateAuthKey
		)
	}
	#else
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona
		)
	}
	#endif

	var personaName: String {
		switch mode {
		case let .general(persona, _):
			return persona.displayName.rawValue
		case let .dApp(_, persona):
			return persona.displayName.rawValue
		}
	}

	var isDappPersona: Bool {
		switch mode {
		case .general:
			return false
		case .dApp:
			return true
		}
	}
}

// MARK: - AccountSection

extension PersonaDetails.State {
	var accountSection: AccountSection? {
		switch mode {
		case .general:
			return nil
		case let .dApp(dApp, persona):
			return .init(dAppName: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName, sharingAccounts: persona.simpleAccounts ?? [])
		}
	}

	struct AccountSection: Equatable {
		let dAppName: String
		let sharingAccounts: OrderedSet<Profile.Network.AccountForDisplay>
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		let store: Store<PersonaDetails.State.AccountSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.AuthorizedDapps.PersonaDetails.accountSharingDescription(viewStore.dAppName))
						.textBlock
						.flushedLeft
						.padding(.vertical, .medium2)
						.padding(.horizontal, .medium1)

					VStack(spacing: .medium3) {
						ForEach(viewStore.sharingAccounts) { account in
							SmallAccountCard(
								account.label.rawValue,
								identifiable: .address(.account(account.address)),
								gradient: .init(account.appearanceID)
							)
							.cornerRadius(.small1)
						}
					}
					.padding(.horizontal, .medium3)

					//	FIXME: Uncomment and enable the functionality
					//	Button(L10n.AuthorizedDapps.PersonaDetails.editAccountSharing) {
					//		viewStore.send(.editAccountSharingTapped)
					//	}
					//	.buttonStyle(.secondaryRectangular)
					//	.padding(.vertical, .large3)
				}
			}
		}
	}
}

// MARK: - DappsSection

extension PersonaDetails.State {
	var dAppsSection: DappsSection? {
		switch mode {
		case let .general(_, dApps):
			return dApps.isEmpty ? nil : dApps
		case .dApp:
			return nil
		}
	}

	typealias DappsSection = IdentifiedArrayOf<PersonaDetails.State.DappInfo>
}

// MARK: - PersonaDetails.View.DappsSection
extension PersonaDetails.View {
	@MainActor
	struct DappsSection: View {
		let store: Store<PersonaDetails.State.DappsSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium1) {
					Text(L10n.AuthorizedDapps.PersonaDetails.authorizedDappsHeading)
						.textBlock
						.flushedLeft
						.padding(.horizontal, .medium1)

					ForEach(viewStore.state) { dApp in
						Card {
							viewStore.send(.dAppTapped(dApp.id))
						} contents: {
							PlainListRow(title: dApp.displayName) {
								DappThumbnail(.known(dApp.thumbnail))
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
			.padding(.vertical, .medium2)
		}
	}
}

// MARK: - InfoSection

private extension PersonaDetails.State {
	var infoSectionViewState: PersonaDetails.View.InfoSection.ViewState {
		switch mode {
		case let .dApp(_, persona: persona):
			return .init(
				dAppInfo: dAppInfo,
				personaName: personaName,
				fields: persona.sharedFields ?? []
			)
		case let .general(persona, _):
			return .init(
				dAppInfo: nil,
				personaName: personaName,
				fields: persona.fields
			)
		}
	}

	var dAppInfo: PersonaDetails.View.InfoSection.ViewState.DappInfo? {
		guard case let .dApp(dApp, persona) = mode else { return nil }
		return .init(
			name: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
			isSharingNothing: persona.sharedFields.isNilOrEmpty
		)
	}
}

private extension PersonaDetails.View.InfoSection.ViewState {
	init(dAppInfo: DappInfo?, personaName: String, fields: IdentifiedArrayOf<Profile.Network.Persona.Field>) {
		self.init(
			dAppInfo: dAppInfo,
			personaName: personaName,
			firstName: fields[id: .givenName]?.value.rawValue,
			lastName: fields[id: .familyName]?.value.rawValue,
			emailAddress: fields[id: .emailAddress]?.value.rawValue,
			phoneNumber: fields[id: .phoneNumber]?.value.rawValue
		)
	}
}

// MARK: - PersonaDetails.View.InfoSection
extension PersonaDetails.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppInfo: DappInfo?
			let personaName: String
			let firstName: String?
			let lastName: String?
			let emailAddress: String?
			let phoneNumber: String?

			struct DappInfo: Equatable {
				let name: String
				let isSharingNothing: Bool
			}
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading, item: viewStore.personaName)

					Separator()

					if let dAppInfo = viewStore.dAppInfo {
						if dAppInfo.isSharingNothing {
							Text(L10n.AuthorizedDapps.PersonaDetails.notSharingAnything(dAppInfo.name))
								.textBlock
						} else {
							Text(L10n.AuthorizedDapps.PersonaDetails.personalDataSharingDescription(dAppInfo.name))
								.textBlock
						}
					}

					if let firstName = viewStore.firstName {
						VPair(heading: L10n.AuthorizedDapps.PersonaDetails.firstName, item: firstName)
					}

					if let lastName = viewStore.lastName {
						VPair(heading: L10n.AuthorizedDapps.PersonaDetails.lastName, item: lastName)
					}

					if let emailAddress = viewStore.emailAddress {
						VPair(heading: L10n.AuthorizedDapps.PersonaDetails.emailAddress, item: emailAddress)
					}

					if let phoneNumber = viewStore.phoneNumber {
						VPair(heading: L10n.AuthorizedDapps.PersonaDetails.phoneNumber, item: phoneNumber)
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}
