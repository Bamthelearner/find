import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"


pub fun main(user: String, maxItems: Int, collections: [String]) : {String : ItemReport} {
	return {}
}


pub struct ItemReport {
	pub let items : [MetadataCollectionItem]
	pub let length : Int // mapping of collection to no. of ids 
	pub let extraIDs : [UInt64]
	pub let shard : String 

	init(items: [MetadataCollectionItem],  length : Int, extraIDs :[UInt64] , shard: String) {
		self.items=items 
		self.length=length 
		self.extraIDs=extraIDs
		self.shard=shard
	}
}

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let name: String
	pub let collection: String // <- This will be Alias unless they want something else
	pub let subCollection: String? // <- This will be Alias unless they want something else

	pub let media  : String
	pub let mediaType : String 
	pub let source : String 

	init(id:UInt64, name: String, collection: String, subCollection: String?, media  : String, mediaType : String, source : String) {
		self.id=id
		self.name=name 
		self.collection=collection 
		self.subCollection=subCollection 
		self.media=media 
		self.mediaType=mediaType 
		self.source=source
	}
}