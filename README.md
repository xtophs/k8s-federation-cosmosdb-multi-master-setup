# Demo: HA with k8s federation and CosmosDb

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

3. Show the DNS zone for federated service 

4. List items using the service - Confirm it's empty
```
$ curl http://localhost:5000/api/items
[]
```

5. Write to to the database through each endpoint
```
$ curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://:5000/api/items
$ curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://:5000/api/items
$ curl -X POST -H "Content-Type: application/json" -d '{"text":"bladeebla" }' http://:5000/api/items
```

6. List items using the service - see items from both collections
```
$ curl http://localhost:5000/api/items
[]
```

7. (optional). Query data from each database using the Azure Portal
