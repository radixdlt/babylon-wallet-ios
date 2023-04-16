import EditPersonaFeature
import FeaturePrelude

// MARK: - View

extension PersonaDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let personaName: String
	}
}

// MARK: - Body

extension PersonaDetails.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					let metadataStore = store.scope(state: \.metadata) { .child(.metadata($0)) }
					PersonaMetadata.View(store: metadataStore)

					AccountSection(store: store)
						.background(.app.gray5)

					Button(L10n.PersonaDetails.deauthorizePersona) {
						viewStore.send(.deauthorizePersonaTapped)
					}
					.buttonStyle(.primaryRectangular(isDestructive: true))
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
				}
			}
			.navigationTitle(viewStore.personaName)
			.alert(store: store.confirmForgetAlert)
		}
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(personaName: persona.displayName.rawValue)
	}
}

private extension PersonaDetails.Store {
	var confirmForgetAlert: AlertPresentationStore<PersonaDetails.ViewAction.ConfirmForgetAlert> {
		scope(state: \.$confirmForgetAlert) { .view(.confirmForgetAlert($0)) }
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let sharingAccounts: OrderedSet<Profile.Network.AccountForDisplay>
		}

		let store: StoreOf<PersonaDetails>

		var body: some View {
			WithViewStore(store, observe: \.accountSectionViewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.PersonaDetails.accountSharingDescription(viewStore.dAppName))
						.textBlock
						.flushedLeft
						.padding(.vertical, .medium2)
						.padding(.horizontal, .medium1)

					VStack(spacing: .medium3) {
						ForEach(viewStore.sharingAccounts) { account in
							AccountButton(
								account.label.rawValue,
								address: account.address.address,
								gradient: .init(account.appearanceID)
							) {
								viewStore.send(.accountTapped(account.address))
							}
						}
					}
					.padding(.horizontal, .medium3)

					Button(L10n.PersonaDetails.editAccountSharing) {
						viewStore.send(.editAccountSharingTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)
				}
			}
		}
	}
}

private extension PersonaDetails.State {
	var accountSectionViewState: PersonaDetails.View.AccountSection.ViewState {
		.init(dAppName: dAppName, sharingAccounts: persona.simpleAccounts ?? [])
	}
}

// MARK: PersonaMetadata

private extension PersonaMetadata.State {
	var viewState: PersonaMetadata.ViewState {
		.init(thumbnail: thumbnail, name: name)
	}
}

extension PersonaMetadata {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let thumbnail: URL?
		let name: String
	}
}

// MARK: - Body

extension PersonaMetadata.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			VStack(spacing: 0) {
				if let thumbnail = viewStore.thumbnail {
					PersonaThumbnail(thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)
				} else {
					PersonaPlaceholder(size: .veryLarge)
						.padding(.vertical, .large2)
				}

				InfoSection(store: store.actionless)

				Button(L10n.PersonaDetails.editPersona) {
					viewStore.send(.editPersonaTapped)
				}
				.buttonStyle(.secondaryRectangular)
				.padding(.vertical, .large3)
			}
		}
		.sheet(store: store.scope(state: \.$editPersona, action: { .child(.editPersona($0)) })) {
			EditPersona.View(store: $0)
		}
	}
}

private extension PersonaMetadata.State {
	var infoSectionViewState: PersonaMetadata.View.InfoSection.ViewState {
		.init(
			dAppInfo: dAppInfo,
			personaName: name,
			firstName: fields[id: .givenName]?.value.rawValue,
			lastName: fields[id: .familyName]?.value.rawValue,
			emailAddress: fields[id: .emailAddress]?.value.rawValue,
			phoneNumber: fields[id: .phoneNumber]?.value.rawValue
		)
	}

	var dAppInfo: PersonaMetadata.View.InfoSection.ViewState.DappInfo? {
		guard case let .dApp(name, _) = mode else { return nil }
		return .init(name: name, isSharingNothing: fields.isEmpty)
	}
}

// MARK: - PersonaMetadata.View.InfoSection
extension PersonaMetadata.View {
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

		let store: Store<PersonaMetadata.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.PersonaDetails.personaNameHeading, item: viewStore.personaName)

					Separator()

					if let dAppInfo = viewStore.dAppInfo {
						if dAppInfo.isSharingNothing {
							Text(L10n.PersonaDetails.notSharingAnything(dAppInfo.name))
								.textBlock
						} else {
							Text(L10n.PersonaDetails.personaDataSharingDescription(dAppInfo.name))
								.textBlock
						}
					}

					if let firstName = viewStore.firstName {
						VPair(heading: L10n.PersonaDetails.firstNameHeading, item: firstName)
					}

					if let lastName = viewStore.lastName {
						VPair(heading: L10n.PersonaDetails.lastNameHeading, item: lastName)
					}

					if let emailAddress = viewStore.emailAddress {
						VPair(heading: L10n.PersonaDetails.emailAddressHeading, item: emailAddress)
					}

					if let phoneNumber = viewStore.phoneNumber {
						VPair(heading: L10n.PersonaDetails.phoneNumberHeading, item: phoneNumber)
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}
