package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowInMemoryEmulator().Start()
	/*
		o := overflow.NewOverflowMainnet().Start()
	*/
	
	//Set up Fungible Token Registry
	o.TransactionFromFile("setFTInfo_flow").
	SignProposeAndPayAsService().
	Args(o.Arguments()).
	RunPrintEventsFull()
	
	// get Info by Alias
	o.ScriptFromFile("getFTInfoByAlias").
	Args(o.Arguments().String("Flow")).
	Run()

	// get Info by TypeIdentifier
	o.ScriptFromFile("getFTInfoByTypeIdentifier").
	Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
	Run()

	// get All Info
	o.ScriptFromFile("getFTInfoAll").
	Args(o.Arguments()).
	Run()

	//Remove Fungible Token Registry By Alias
	o.TransactionFromFile("removeFTInfoByAlias").
	SignProposeAndPayAsService().
	Args(o.Arguments().String("Flow")).
	RunPrintEventsFull()

	//Set up Fungible Token Registry Again (for testing out delete)
	o.TransactionFromFile("setFTInfo_flow").
	SignProposeAndPayAsService().
	Args(o.Arguments()).
	RunPrintEventsFull()

	//Remove Fungible Token Registry By Type Identifier
	o.TransactionFromFile("removeFTInfoByTypeIdentifier").
	SignProposeAndPayAsService().
	Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
	RunPrintEventsFull()


}
