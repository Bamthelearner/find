package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowInMemoryEmulator().Start()
	/*
		o := overflow.NewOverflowMainnet().Start()
	*/
	
	//first step create the adminClient as the fin user
	o.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("find")).
		RunPrintEventsFull()

	//Set up NonFungibleToken Registry
	o.TransactionFromFile("setNFTInfo_Dandy").
		SignProposeAndPayAs("find").
		Args(o.Arguments()).
		RunPrintEventsFull()
	
	// get Info by Alias
	o.ScriptFromFile("getNFTInfoByAlias").
		Args(o.Arguments().String("Dandy")).
		Run()

	// get Info by TypeIdentifier
	o.ScriptFromFile("getNFTInfoByTypeIdentifier").
		Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.Collection")).
		Run()

	// get All Info
	o.ScriptFromFile("getNFTInfoAll").
		Args(o.Arguments()).
		Run()

	//Remove NonFungibleToken Registry By Alias
	o.TransactionFromFile("removeNFTInfoByAlias").
		SignProposeAndPayAs("find").
		Args(o.Arguments().String("Dandy")).
		RunPrintEventsFull()

	//Set up NonFungibleToken Registry Again (for testing out delete)
	o.TransactionFromFile("setNFTInfo_Dandy").
		SignProposeAndPayAs("find").
		Args(o.Arguments()).
		RunPrintEventsFull()

	//Remove NonFungibleToken Registry By Type Identifier
	o.TransactionFromFile("removeNFTInfoByTypeIdentifier").
		SignProposeAndPayAs("find").
		Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.Collection")).
		RunPrintEventsFull()


}
