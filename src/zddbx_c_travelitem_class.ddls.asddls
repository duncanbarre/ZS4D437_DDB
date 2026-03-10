extend view entity ZDDB_C_TravelItem with {
    @Consumption.valueHelpDefinition: [  { entity : { name: '/LRN/437_I_ClassStdVH',
                                                      element: 'ClassID'  }}] 
    Item.ZZClassZDD as ZZClassZDD 
}
