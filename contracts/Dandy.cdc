import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Profile from "../contracts/Profile.cdc"
import FindViews from "../contracts/FindViews.cdc"

/*
The first time a dandy is sold we will take 10%, on subsequent sales we will take 0% from Dandy. But 5% from market. 
So primary is total 15%, secondary is total 5%
*/

//TODO: review all permissions and events
pub contract Dandy: NonFungibleToken {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub var totalSupply: UInt64


	/*store all valid type converters for Dandys
	This is to be able to make the contract compatible with the forthcomming NFT standard. 

	If a Dandy supports a type with the same Identifier as a key here all the ViewConverters convertTo types are added to the list of available types
	When resolving a type if the Dandy does not itself support this type check if any viewConverters do
	*/
	access(account) var viewConverters: {String: [{ViewConverter}]}

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, minter:String, name:String, description:String)

	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}
	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		access(self) var nounce: UInt64
		access(self) var primaryCutPaid: Bool
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String
		access(contract) let description: String
		access(contract) let minterPlatform: MinterPlatform


		init(name: String, description: String, schemas: {String: ViewInfo},  minterPlatform: MinterPlatform) {
			self.id = self.uuid
			self.schemas=schemas
			self.minterPlatform=minterPlatform
			self.name=name
			self.description=description
			self.nounce=0
			self.primaryCutPaid=false
		}

		access(account) fun setPrimaryCutPaid() {
			self.primaryCutPaid=true

		}
		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}


		pub fun getViews() : [Type] {

			var views : [Type]=[]
			views.append(Type<MinterPlatform>())
			views.append(Type<FindViews.Nounce>())
			views.append(Type<String>())
			views.append(Type<MetadataViews.Display>())
			views.append(Type<FindViews.Royalties>())

			//if any specific here they will override
			for s in self.schemas.keys {
				if !views.contains(self.schemas[s]!.typ) {
					views.append(self.schemas[s]!.typ)
				}
			}

			//ViewConverter: If there are any viewconverters that add new types that can be resolved add them
			for v in views {
				if Dandy.viewConverters.containsKey(v.identifier) {
					for converter in Dandy.viewConverters[v.identifier]! {
						//I wants sets in cadence...
						if !views.contains(converter.to){ 
							views.append(converter.to)
						}
					}
				}
			}

			return views
		}

		access(self) fun resolveRoyalties() : FindViews.Royalties {
			let royalties : [FindViews.Royalty] = []

			if self.schemas.containsKey(Type<FindViews.Royalty>().identifier) {
				royalties.append(self.schemas[Type<FindViews.Royalty>().identifier]!.result as! FindViews.Royalty)
			}

			if self.schemas.containsKey(Type<FindViews.Royalties>().identifier) {
				let multipleRoylaties=self.schemas[Type<FindViews.Royalties>().identifier]!.result as! FindViews.Royalties
				royalties.appendAll(multipleRoylaties.getRoyalties())
			}

			//we only charge platform primary sale cut once
			if !self.primaryCutPaid {
				let royalty=FindViews.Royalty(receiver : self.minterPlatform.platform, cut: self.minterPlatform.platformPercentCut, description:"platform")
				royalties.append(royalty)
			}
			return FindViews.Royalties(cutInfos:royalties)
		}

		pub fun resolveDisplay() : MetadataViews.Display {
			var thumbnail : AnyStruct{MetadataViews.File}? = nil
			if self.schemas.containsKey(Type<FindViews.Files>().identifier) {
				let medias=self.schemas[Type<FindViews.Files>().identifier]!.result as! FindViews.Files
				if medias.media.containsKey("thumbnail") {
					thumbnail=medias.media["thumbnail"] as! AnyStruct{MetadataViews.File}
				}
			}

			if self.schemas.containsKey(Type<MetadataViews.HTTPFile>().identifier) {
				thumbnail=self.schemas[Type<MetadataViews.HTTPFile>().identifier]!.result as! MetadataViews.HTTPFile
			}

			if self.schemas.containsKey(Type<MetadataViews.IPFSFile>().identifier) {
				thumbnail=self.schemas[Type<MetadataViews.IPFSFile>().identifier]!.result as! MetadataViews.IPFSFile
			}

			if self.schemas.containsKey(Type<FindViews.SharedMedia>().identifier) {
				thumbnail=self.schemas[Type<FindViews.SharedMedia>().identifier]!.result as! AnyStruct{MetadataViews.File}
			}

			return MetadataViews.Display(
				name: self.name,
				description: self.description,
				thumbnail: thumbnail!
			)


		}

		pub fun resolveSourceUri() : String {
			return "implement me"

		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		pub fun resolveView(_ type: Type): AnyStruct {

			if type == Type<MinterPlatform>() {
				return self.minterPlatform
			}

			if type == Type<FindViews.Nounce>() {
				return FindViews.Nounce(self.nounce)
			}

			if type == Type<FindViews.Royalties>() {
				return self.resolveRoyalties()
			}

			if type == Type<MetadataViews.Display>() {
				return self.resolveDisplay()
			}

			if type == Type<String>() {
				return self.name
			}

			if self.schemas.keys.contains(type.identifier) {
				return self.schemas[type.identifier]!.result
			}

			//Viewconverter: This is an example on how you as the last step in resolveView can check if there are converters for your type and run them
			for converterValue in Dandy.viewConverters.keys {
				for converter in Dandy.viewConverters[converterValue]! {
					if converter.to == type {
						let value= self.resolveView(converter.from)
						return converter.convert(value)
					}
				}
			}
			return nil
		}

	}


	pub resource interface CollectionPublic {
		access(account) fun setPrimaryCutPaid(_ id: UInt64)
		pub fun getIDsFor(minter: String): [UInt64] 
		pub fun getMinters(): [String] 
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")


			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			token.increaseNounce()

			let id: UInt64 = token.id

			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		pub fun getMinters(): [String] {

			let minters: [String] = []
			for id in self.ownedNFTs.keys {
				let nft=self.borrow(id)
				let minter=nft.minterPlatform.name
				if !minters.contains(minter) {
					minters.append(minter)
				}
			}
			return minters
		}

		pub fun getIDsFor(minter: String): [UInt64] {

			let ids: [UInt64] = []
			for id in self.ownedNFTs.keys {
				let nft=self.borrow(id)
				if nft.minterPlatform.name == minter {
					ids.append(id)
				}
			}
			return ids
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}

			return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}

			let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
			return nft as! &Dandy.NFT
		}

		pub fun borrow(_ id: UInt64): &NFT {
				pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}
			let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
			return nft as! &Dandy.NFT
		}

		access(account) fun setPrimaryCutPaid(_ id: UInt64) {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}
			self.borrow(id).setPrimaryCutPaid()
		}
		destroy() {
			destroy self.ownedNFTs 
		}
	}

	//TODO: this needs some sort of url information to determine the sourceURI of nfts minted with it
	//TODO: can these fields really be public? Not sure that is wise
	pub struct MinterPlatform {
		pub let platform: Capability<&{FungibleToken.Receiver}>
		pub let platformPercentCut: UFix64
		pub let name: String

		init(name: String, platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64) {
			self.platform=platform
			self.platformPercentCut=platformPercentCut
			self.name=name
		}
	}

	access(account)  fun createForge(platform: MinterPlatform) : @Forge {
		return <- create Forge(platform:platform)
	}

	access(account) fun mintNFT(name: String, description: String, platform:MinterPlatform, schemas: [AnyStruct]) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			//if you send in display we ignore it, this will be made for you
			if s.getType() != Type<MetadataViews.Display>() {
				views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
			}
		}

		let nft <-  create NFT(name: name, description:description, schemas:views, minterPlatform: platform)

		emit Minted(id:nft.id, minter:nft.minterPlatform.name, name: name, description:description)
		return <-  nft
	}

	access(account) fun setViewConverters(from: Type, converters: [AnyStruct{ViewConverter}]) {
		Dandy.viewConverters[from.identifier] = converters
	}

	//This is not used right now but might be here for white label things
	pub resource Forge {
		access(contract) let platform: MinterPlatform

		init(platform: MinterPlatform) {
			self.platform=platform
		}

		pub fun mintNFT(name: String, description: String, schemas: [AnyStruct]) : @NFT {
			return <- Dandy.mintNFT(name: name, description: description, platform: self.platform, schemas: schemas)
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}


	/// This struct interface is used on a contract level to convert from one View to another. 
	/// See Dandy nft for an example on how to convert one type to another
	pub struct interface ViewConverter {
		pub let to: Type
		pub let from: Type

		pub fun convert(_ value:AnyStruct) : AnyStruct
	}

	init() {
		// Initialize the total supply
		self.totalSupply=0
		self.CollectionPublicPath = /public/findDandy
		self.CollectionPrivatePath = /private/findDandy
		self.CollectionStoragePath = /storage/findDandy
		self.viewConverters={}

		emit ContractInitialized()
	}
}