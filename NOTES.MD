# Workbook NOTES

## Setting up CouchDB on Minikube

### Method

- We will try to setup a 3-pod cluster of CouchDB services as a Stateful Set.
- Each pod will have its own persistent storage volume on a dedicated NFS Server Instance
- To mimic this, we set up a VM running the NFS Service (in this case, we use debian)
- 
