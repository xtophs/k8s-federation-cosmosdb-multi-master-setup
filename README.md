# Demo: HA with k8s federation and CosmosDb

This Demo configures an multi-region HA setup with [kubernetes federation](https://kubernetes.io/docs/concepts/cluster-administration/federation/) with [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) and a [multi-master, multi-region CosmosDb](https://docs.microsoft.com/en-us/azure/cosmos-db/multi-region-writers).

The architecture deploys microservices to access data in CosmosDb into 2 federated kubernetes clusters:
![](images/multi-master-cosmos.png)

The SLA of

* 2 geo-distributed k8s compute clusters with an availability SLA of 99.95% each, 
* a geo-distributed CosmosDb with an availability SLA of 99.99% and 
* Azure DNS, also with 99.99% 

combined into a single solution reaches **99.99%** following [@hanuk's calculations](http://download.microsoft.com/download/1/C/2/1C23BE8E-D0D8-448C-BF38-A0708C9EF9F5/Building_Mission_Critical_Systems_on_Cloud_Platforms.pdf). 


## Setup Federation  
Follow the steps [here](https://github.com/xtophs/k8s-setup-federation-cluster)

## Setup Cosmos Db
Make sure you've [isntalled the latest Azure CLI version](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). You version needs to be 2.0.10 or later to manage cosmosdb. 

The setup configures 2 cosmosdb instances according to [Multi-master globally replicated database architectures with Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/multi-region-writers)

1. Create Resource Group
```
az group create -l westus -n xtoph-delete-cosmosdb
```

2. Create 2 cosmos db instances
```
az cosmosdb create -g xtoph-delete-cosmosdb -n cosmos-west --locations westus=0 eastus=1 
az cosmosdb create -g xtoph-delete-cosmosdb -n cosmos-east --locations eastus=0 westus=1 
```

3. Create Databases and collection
```
az cosmosdb database create -g xtoph-delete-cosmosdb -n cosmos-west -d mydb
az cosmosdb collection create -g xtoph-delete-cosmosdb -n cosmos-west -d mydb -c items
az cosmosdb database create -g xtoph-delete-cosmosdb -n cosmos-east -d mydb
az cosmosdb collection create -g xtoph-delete-cosmosdb -n cosmos-east -d mydb -c items
```

## Deploy demo app
The code for the demo at is at [https://github.com/xtophs/cosmosdb-multi-master]

1. Deploy config maps into _each cluster_
```
kubectl create -f configmaps/cosmos-west-configmap.yaml --context=fed-west
kubectl create -f configmaps/cosmos-east-configmap.yaml --context=fed-east
```

2. Deploy the ReplicaSet into the _federated cluster_
```
kubectl create -f rs/items-rs.yaml --context=myfederation
```

3. Deploy the service into the _federated cluster_
```
kubectl create -f svc/items-svc.yaml --context=myfederation
```

## Demo the demo

1. Query the west database from the Azure Portal. Confirm it's empty

2. Query the east database from the Azure Portal. Confirm it's empty

3. Show the DNS zone for federated service and copy the DNS Name for the federation A Record.

4. Confirm the service returns an empty response - with cosmosdata-svc.default.myfederation.svc.xtophs.com as federation DNS name.  
```
$ curl http://cosmosdata-svc.default.myfederation.svc.eastus.xtophs.com:5000/api/items
[]
```

5. Write to to the database through each endpoint.


Results from the east partition (note the location: cosmos-east-eastus.documents.azure.com )
```
$ curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://cosmosdata-svc.default.myfederation.svc.eastus.xtophs.com:5000/api/items
```

Results from the west partition (note the location: cosmos-west-westus.documents.azure.com):
```
$ curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://cosmosdata-svc.default.myfederation.svc.westus.xtophs.com:5000/api/items
```

6. List items using the service - see items from both collections
```
$ curl http://localhost:5000/api/items
[]
```

Aggregated results with both locations:
```
$  curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://cosmosdata-svc.default.myfederation.svc.westus.xtophs.com:5000/api/items
```


7. (optional). Query data from each database using the Azure Portal
