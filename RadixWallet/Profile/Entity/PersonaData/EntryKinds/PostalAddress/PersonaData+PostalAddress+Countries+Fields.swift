import EngineToolkit

extension PersonaData.PostalAddress.CountryOrRegion {
	var fields: [[PersonaData.PostalAddress.Field.Discriminator]] {
		switch self {
		// MARK: A

		case .afghanistan, .albania, .angola, .antiguaAndBarbuda, .aruba,
		     .barbados, .benin, .bhutan, .bolivia, .botswana, .burundi,
		     .cameroon, .centralAfricanRepublic, .chad, .comoros, .curacao,
		     .djibouti, .dominica,
		     .equatorialGuinea, .eritrea,
		     .ghana, .grenada, .guyana,
		     .libya,
		     .mali, .mauritania,
		     .namibia,
		     .republicOfTheCongo, .rwanda,
		     .saintLucia, .saintVincentAndTheGrenadines, .samoa, .saoTomeAndPrincipe, .seychelles, .sierraLeone, .sintMaarten, .solomonIslands,
		     .tanzania, .theGambia, .timorLeste, .togo, .tonga, .trinidadAndTobago,
		     .tuvalu,
		     .uganda,
		     .vanuatu,
		     .zimbabwe:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .algeria, .andorra, .armenia, .austria, .azerbaijan,
		     .belgium, .bosniaAndHerzegovinia, .bulgaria,
		     .capeVerde, .chile, .costaRica, .coteDIvoire, .croatia, .cuba, .cyprus, .czechRepublic,
		     .denmark,
		     .estonia, .ethiopia,
		     .faroeIslands, .finland, .france, .frenchGuiana,
		     .gabon, .georgia, .germany, .greece, .greenland, .guadeloupe, .guatemala, .guinea, .guineaBissau,
		     .haiti,
		     .iceland, .iran,
		     .laos, .liberia, .liechtenstein, .lithuania, .luxembourg,
		     .madagascar, .marshallIslands, .martinique, .mayotte, .moldova, .monaco, .montenegro, .morocco,
		     .netherlands, .newCaledonia, .niger, .northMacedonia, .norway,
		     .palestinianTerritories, .paraguay, .poland, .portugal,
		     .qatar,
		     .reunion, .romania,
		     .saintBarthelemy, .saintMartin, .senegal, .serbia, .slovakia, .slovenia,
		     .sweden, .switzerland, .syria,
		     .tajikistan, .tunisia, .turkmenistan,
		     .vatican,
		     .yemen,
		     .zambia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .anguilla, .nauru:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.countryOrRegion],
			]

		case .argentina, .belarus, .kuwait, .mozambique, .panama, .sanMarino:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .australia:
			[
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.state, .postalCode],
				[.countryOrRegion],
			]

		// MARK: B

		case .bahrain, .bangladesh, .bermuda, .bruneiDarussalam, .burkinaFaso,
		     .cambodia,
		     .democraticRepublicOfTheCongo,
		     .jamaica,
		     .latvia, .lebanon, .lesotho,
		     .malawi, .maldives, .mongolia, .myanmar,
		     .nepal,
		     .pakistan, .peru,
		     .singapore:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .belize:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		case .brazil:
			[
				[.streetLine0],
				[.streetLine1],
				[.neighbourhood],
				[.city],
				[.state],
				[.postalCode],
				[.countryOrRegion],
			]

		case .britishVirginIslands,
		     .montserrat:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.countryOrRegion],
			]

		// MARK: C

		case .canada,
		     .indonesia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .carribeanNetherlands,
		     .kiribati,
		     .theBahamas:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .caymanIslands,
		     .cookIslands,
		     .turksAndCaicosIslans:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .chinaMainland:
			[
				[.countryOrRegion],
				[.province],
				[.prefectureLevelCity],
				[.district],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .colombia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.department],
				[.countryOrRegion],
			]

		// MARK: D

		case .dominicanRepublic:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalDistrict],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: E

		case .elSalvador, .honduras, .uruguay:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .ecuador, .mauritius, .southSudan, .sudan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .egypt:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.governorate],
				[.countryOrRegion],
			]

		case .eswatini, .falklandIslands, .iraq, .isleOfMan, .kenya, .malta, .saintHelena, .southGeorgiaAndSouthSandwichIslands, .sriLanka:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

        // MARK: F

		case .fiji:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.city],
				[.countryOrRegion],
			]

		case .frenchPolynesia, .saintKittsAndNevis:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.islandName],
				[.countryOrRegion],
			]

		// MARK: G

		case .gibraltar:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postcode],
				[.countryOrRegion],
			]

		// MARK: H

		case .hongKong:
			[
				[.countryOrRegion],
				[.region, .district],
				[.streetLine0],
				[.streetLine1],
			]

		case .hungary, .kyrgyzstan:
			[
				[.postalCode, .city],
				[.streetLine0],
				[.streetLine1],
				[.countryOrRegion],
			]

		// MARK: I

		case .india:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.state],
				[.countryOrRegion],
			]

		case .ireland:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county, .postalCode],
				[.countryOrRegion],
			]

		case .israel, .italy, .spain:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		// MARK: J

		case .japan:
			[
				[.postalCode],
				[.prefecture, .countySlashCity],
				[.furtherDivisionsLine0],
				[.furtherDivisionsLine1],
				[.countryOrRegion],
			]

		case .jordan:
			[
				[.postalDistrict],
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		// MARK: K

		case .kazakhstan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.region],
				[.countryOrRegion],
				[.postalCode],
			]

		// MARK: M

		case .macao:
			[
				[.countryOrRegion],
				[.district, .city],
				[.streetLine0],
				[.streetLine1],
			]

		case .malaysia, .mexico:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.state],
				[.countryOrRegion],
			]

		case .micronesia, .puertoRico, .unitedStates, .usVirginIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		// MARK: N

		case .newZealand:
			[
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .nicaragua:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.department],
				[.countryOrRegion],
			]

		case .nigeria, .venezuela:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.state],
				[.countryOrRegion],
			]

		case .northKorea:
			[
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
			]

		// MARK: O

		case .oman:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		// MARK: P

		case .palau:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state],
				[.zip],
				[.countryOrRegion],
			]

		case .papuaNewGuinea:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.province],
				[.countryOrRegion],
			]

		case .philippines:
			[
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision, .postalCode],
				[.city, .countryOrRegion],
			]

		// MARK: R

		case .russia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.subjectOfTheFederation],
				[.countryOrRegion],
				[.postalCode],
			]

		// MARK: S

		case .saudiArabia:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .somalia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.region, .postalCode],
				[.countryOrRegion],
			]

		case .southAfrica, .ukraine:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCode],
				[.countryOrRegion],
			]

		case .southKorea:
			[
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .suriname:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.countryOrRegion],
			]

		// MARK: T

		case .taiwan:
			[
				[.countryOrRegion],
				[.zip, .countySlashCity],
				[.townshipSlashDistrict],
				[.streetLine0],
				[.streetLine1],
			]

		case .thailand:
			[
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .turkey:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .district],
				[.city, .countryOrRegion],
			]

		// MARK: U

		case .unitedArabEmirates:
			[
				[.streetLine0],
				[.streetLine1],
				[.area],
				[.city],
				[.countryOrRegion],
			]

		case .unitedKingdom:
			[
				[.streetLine0],
				[.streetLine1],
				[.townSlashCity],
				[.county],
				[.postcode],
				[.countryOrRegion],
			]

		case .uzbekistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
				[.postalCode],
			]

		// MARK: V

		case .vietnam:
			[
				[.streetLine0],
				[.streetLine1],
				[.province],
				[.city, .postalCode],
				[.countryOrRegion],
			]
		}
	}
}
