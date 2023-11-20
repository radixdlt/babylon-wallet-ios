import EngineToolkit

// MARK: - PersonaData.PostalAddress.CountryOrRegion
extension PersonaData.PostalAddress {
	public enum CountryOrRegion: String, Sendable, Hashable, Codable, CaseIterable, Identifiable {
		// MARK: A
		case afghanistan
		case albania
		case algeria
		case andorra
		case angola
		case anguilla
		case antiguaAndBarbuda
		case argentina
		case armenia
		case aruba
		case australia
		case austria
		case azerbaijan

		// MARK: B
		case bahrain
		public static let bahamas = Self.theBahamas
		case bangladesh
		case barbados
		case belarus
		case belgium
		case belize
		case benin
		case bermuda
		case bhutan
		case bolivia
		case bosniaAndHerzegovinia
		case botswana
		case brazil
		case britishVirginIslands
		case bruneiDarussalam
		case bulgaria
		case burkinaFaso
		case burundi

		// MARK: C
		case cambodia
		case cameroon
		case canada
		case capeVerde
		case carribeanNetherlands
		case caymanIslands
		case centralAfricanRepublic
		case chad
		case chile
		case chinaMainland
		case colombia
		case comoros
		case cookIslands
		case costaRica

		/// Côte d'Ivoire
		case coteDIvoire

		case croatia
		case cuba

		/// Curaçao
		case curacao

		case cyprus
		case czechRepublic

		// MARK: D

		/// aka "Congo-Kinshasa" aka "DRC" (formerly known as "Zaire")
		case democraticRepublicOfTheCongo

		case denmark
		case djibouti
		case dominica
		case dominicanRepublic

		// MARK: E
		case ecuador
		case egypt
		case elSalvador
		case equatorialGuinea
		case eritrea
		case estonia
		case eswatini
		case ethiopia

		// MARK: F
		case falklandIslands
		case faroeIslands
		case fiji
		case finland
		case france
		case frenchGuiana
		case frenchPolynesia

		// MARK: G
		case gabon
		case georgia
		public static let gambia = Self.theGambia
		case germany
		case ghana
		case gibraltar
		case greece
		case greenland
		case grenada
		case guadeloupe
		case guatemala
		case guinea
		case guineaBissau
		case guyana

		// MARK: H
		case haiti
		case honduras
		case hongKong
		case hungary

		// MARK: I
		case iceland
		case india
		case indonesia
		case iran
		case iraq
		case ireland
		case isleOfMan
		case israel
		case italy
		public static let ivoryCoast = Self.coteDIvoire

		// MARK: J
		case jamaica
		case japan
		case jordan

		// MARK: K
		case kazakhstan
		case kenya
		case kiribati
		case kuwait
		case kyrgyzstan

		// MARK: L
		case laos
		case latvia
		case lebanon
		case lesotho
		case liberia
		case libya
		case liechtenstein
		case lithuania
		case luxembourg

		// MARK: M
		case macao
		case madagascar
		case malawi
		case malaysia
		case maldives
		case mali
		case malta
		case marshallIslands
		case martinique
		case mauritania
		case mauritius
		case mayotte
		case mexico
		case micronesia
		case moldova
		case monaco
		case mongolia
		case montenegro
		case montserrat
		case morocco
		case mozambique
		case myanmar

		// MARK: N
		case namibia
		case nauru
		case nepal
		case netherlands
		case newCaledonia
		case newZealand
		case nicaragua
		case niger
		case nigeria
		case northKorea
		case northMacedonia
		case norway

		// MARK: O
		case oman

		// MARK: P
		case pakistan
		case palau
		case palestinianTerritories
		case panama
		case papuaNewGuinea
		case paraguay
		case peru
		case philippines
		case poland
		case portugal
		case puertoRico

		// MARK: Q
		case qatar

		// MARK: R

		/// aka "Congo-Brazzaville" or simply "Congo"
		case republicOfTheCongo

		/// Réunion
		case reunion

		case romania
		case russia
		case rwanda

		// MARK: S

		/// Saint Berthélemy
		case saintBarthelemy
		case saintHelena
		case saintKittsAndNevis
		case saintLucia
		case saintMartin
		case saintVincentAndTheGrenadines
		case samoa
		case sanMarino
		case saoTomeAndPrincipe
		case saudiArabia
		case senegal
		case serbia
		case seychelles
		case sierraLeone
		case singapore
		case sintMaarten
		case slovakia
		case slovenia
		case solomonIslands
		case somalia
		case southAfrica
		case southGeorgiaAndSouthSandwichIslands
		case southKorea
		case southSudan
		case spain
		case sriLanka
		case sudan
		case suriname
		case sweden
		case switzerland
		case syria

		// MARK: T
		case taiwan
		case tajikistan
		case tanzania
		case thailand
		case theBahamas
		case theGambia

		/// Timor-Leste
		case timorLeste

		case togo
		case tonga
		case trinidadAndTobago
		case tunisia
		case turkey
		case turkmenistan
		case turksAndCaicosIslans
		case tuvalu

		// MARK: U

		/// U.S. Virgin islands
		case usVirginIslands
		case uganda
		case ukraine
		case unitedArabEmirates
		case unitedKingdom
		case unitedStates
		case uruguay
		case uzbekistan

		// MARK: V
		case vanuatu
		case vatican
		case venezuela
		case vietnam

		// MARK: Y
		case yemen

		// MARK: Z
		case zambia
		case zimbabwe
	}
}

extension PersonaData.PostalAddress.CountryOrRegion {
	public typealias ID = RawValue
	public var id: ID { rawValue }
}
