import EngineToolkit

// MARK: - Profile.Network.AuthorizedDapp
public typealias DappDefinitionAddress = AccountAddress

extension DappDefinitionAddress {
	/// This address is just a placeholder for now to be compatible with DappInteractor flow
	public static let wallet: Self = try! .init(validatingAddress: "account_tdx_21_128jk8476rq97wjv90nzjvr2nslpj04dcex7lh8tv80qvv8yfx59faw")
}

// MARK: - Profile.Network.AuthorizedDapp
extension Profile.Network {
	/// A connection made between a Radix Dapp and the user.
	public struct AuthorizedDapp:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public let networkID: Radix.Network.ID

		public let dAppDefinitionAddress: DappDefinitionAddress

		/// Will be nil if we failed to fetch the DappMeta data from Ledger for some reason, and
		/// which is allowed if `isDeveloperMode: true` is set.
		public let displayName: NonEmptyString?

		// mutable so that we can add new authorized personas
		public var referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple>

		public init(
			networkID: Radix.Network.ID,
			dAppDefinitionAddress: DappDefinitionAddress,
			displayName: NonEmptyString?,
			referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple> = .init()
		) {
			self.networkID = networkID
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.displayName = displayName
			self.referencesToAuthorizedPersonas = referencesToAuthorizedPersonas
		}
	}
}

extension Profile.Network.AuthorizedDapp {
	public var id: DappDefinitionAddress {
		dAppDefinitionAddress
	}
}

// MARK: - DappOrigin
public struct DappOrigin: Sendable, Hashable, Codable {
	public static let wallet: DappOrigin = {
		let walletAppScheme = "com.radixpublishing.radixwallet.ios"
		return .init(urlString: .init(stringLiteral: walletAppScheme), url: .init(string: walletAppScheme)!)
	}()

	public let urlString: NonEmptyString
	public let url: URL

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(urlString.rawValue)
	}

	public init(urlString: NonEmptyString, url: URL) {
		self.urlString = urlString
		self.url = url
	}

	struct InvalidOriginURL: Error {}

	public init(string: String) throws {
		guard
			let urlNonEmpty = NonEmptyString(rawValue: string),
			let url = URL(string: string)
		else {
			throw InvalidOriginURL()
		}
		self.init(urlString: urlNonEmpty, url: url)
	}

	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		let urlStringString = try singleValueContainer.decode(String.self)
		try self.init(string: urlStringString)
	}
}

// MARK: - RequestedNumber
// TODO: evolve this into an enum mirroring `SelectionRequirement` in `Selection.swift` to enable case switching.
//
// Things to keep in mind:
//
// - It will require a custom Codable implementation to make up for the move from struct(ured) to enum. Make sure implementation matches CAP-21's spec by writing some XCTAssertJSON tests beforehand.
// - Don't just typealias NumberOfAccounts = SelectionRequirement, as they're not the same conceptually and should be allowed to evolve independently!
public struct RequestedNumber: Sendable, Hashable, Codable {
	public enum Quantifier: String, Sendable, Hashable, Codable {
		case exactly
		case atLeast
	}

	public let quantifier: Quantifier
	public let quantity: Int

	public var isValid: Bool {
		switch (quantifier, quantity) {
		case (.exactly, 0):
			false
		case (_, ..<0):
			false
		default:
			true
		}
	}

	public static func exactly(_ quantity: Int) -> Self {
		.init(quantifier: .exactly, quantity: quantity)
	}

	public static func atLeast(_ quantity: Int) -> Self {
		.init(quantifier: .atLeast, quantity: quantity)
	}
}

// MARK: - Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple
extension Profile.Network.AuthorizedDapp {
	public struct AuthorizedPersonaSimple:
		Sendable,
		Hashable,
		Identifiable,
		Codable
	{
		public typealias ID = IdentityAddress
		/// The globally unique identifier of a Persona is its address, used
		/// to lookup persona
		public let identityAddress: IdentityAddress

		/// Date of last login for this persona.
		public var lastLogin: Date

		public typealias SharedAccounts = Shared<AccountAddress>
		/// List of "ongoing accountAddresses" that user given the dApp access to.
		public var sharedAccounts: SharedAccounts?

		public struct SharedPersonaData:
			Sendable,
			Hashable,
			Codable
		{
			public typealias SharedCollection = Shared<PersonaDataEntryID>

			public var name: PersonaDataEntryID?
			public var dateOfBirth: PersonaDataEntryID?
			public var companyName: PersonaDataEntryID?

			public var emailAddresses: SharedCollection?
			public var phoneNumbers: SharedCollection?
			public var urls: SharedCollection?
			public var postalAddresses: SharedCollection?
			public var creditCards: SharedCollection?

			public var entryIDs: Set<PersonaDataEntryID> {
				var ids: [PersonaDataEntryID] = [
					name, dateOfBirth, companyName,
				].compactMap { $0 }
				ids.append(contentsOf: emailAddresses?.ids ?? [])
				ids.append(contentsOf: phoneNumbers?.ids ?? [])
				ids.append(contentsOf: urls?.ids ?? [])
				ids.append(contentsOf: postalAddresses?.ids ?? [])
				ids.append(contentsOf: creditCards?.ids ?? [])

				// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
				// we do not forget to handle it here.
				switch PersonaData.Entry.Kind.fullName {
				case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
				}

				return Set(ids)
			}

			public init(
				name: PersonaDataEntryID? = nil,
				dateOfBirth: PersonaDataEntryID? = nil,
				companyName: PersonaDataEntryID? = nil,
				emailAddresses: SharedCollection? = nil,
				phoneNumbers: SharedCollection? = nil,
				urls: SharedCollection? = nil,
				postalAddresses: SharedCollection? = nil,
				creditCards: SharedCollection? = nil
			) {
				self.name = name
				self.dateOfBirth = dateOfBirth
				self.companyName = companyName

				self.emailAddresses = emailAddresses
				self.phoneNumbers = phoneNumbers
				self.urls = urls
				self.postalAddresses = postalAddresses
				self.creditCards = creditCards

				// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
				// we do not forget to handle it here.
				switch PersonaData.Entry.Kind.fullName {
				case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
				}
			}
		}

		public var sharedPersonaData: SharedPersonaData

		public struct Shared<ID>:
			Sendable,
			Hashable,
			Codable where ID: Sendable & Hashable & Codable
		{
			public typealias Number = RequestedNumber
			public let request: Number
			public var ids: OrderedSet<ID>

			public init(
				ids: OrderedSet<ID>,
				forRequest request: Number
			) throws {
				try Self.validate(ids: ids, forRequest: request)
				self.request = request
				self.ids = ids
			}
		}

		public init(
			identityAddress: IdentityAddress,
			lastLogin: Date,
			sharedAccounts: SharedAccounts?,
			sharedPersonaData: SharedPersonaData
		) {
			self.identityAddress = identityAddress
			self.lastLogin = lastLogin
			self.sharedAccounts = sharedAccounts
			self.sharedPersonaData = sharedPersonaData
		}
	}
}

// MARK: - NotEnoughEntiresProvided
struct NotEnoughEntiresProvided: Swift.Error {}

// MARK: - InvalidNumberOfEntries
struct InvalidNumberOfEntries: Swift.Error {}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.Shared {
	public static func validate(
		ids: OrderedSet<ID>,
		forRequest request: Number
	) throws {
		switch request.quantifier {
		case .atLeast:
			guard ids.count >= request.quantity else {
				throw NotEnoughEntiresProvided()
			}
		// all good
		case .exactly:
			guard ids.count == request.quantity else {
				throw InvalidNumberOfEntries()
			}
			// all good
		}
	}

	public mutating func update(_ new: OrderedSet<ID>) throws {
		try Self.validate(ids: new, forRequest: self.request)
		self.ids = new
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple {
	public var id: ID {
		identityAddress
	}
}

extension Profile.Network.AuthorizedDapp {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"dAppDefinitionAddress": dAppDefinitionAddress,
				"displayName": String(describing: displayName),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		dAppDefinitionAddress: \(dAppDefinitionAddress),
		displayName: \(String(describing: displayName)),
		"""
	}
}
