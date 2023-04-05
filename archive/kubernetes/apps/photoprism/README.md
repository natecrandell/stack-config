View in [GitLab](https://gitlab.crandell.us/config/kubernetes/-/tree/master/apps/photoprism)

----

I grabbed the [official](https://docs.photoprism.org/getting-started/docker-compose/) docker-compose file
```
wget https://dl.photoprism.org/docker/docker-compose.yml
```
and converting it with kompose
```
kompose convert
```

----

### Changes to mariadb-deployment.yaml:

```
spec:template:spec:containers:env:
  - MYSQL_PASSWORD
  - MYSQL_ROOT_PASSWORD
spec:template:spec:
  - restartPolicy: OnFailure
```

Looks like I'll need to figure out how to:
 - use k8s secrets
 - configure storageclass for gluster gvol-misc (photos library)
 - make sure a pvc uses storage class
