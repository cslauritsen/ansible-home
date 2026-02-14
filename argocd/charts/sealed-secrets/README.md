# Sealed Secrets Controller
The chart I installed was bitnami, which got acquired and is commercializing everything. 
# Chart

The chart is vendored into this repo in the `chart` directory.

# Image
Basic dup of the image:

    VER=0.27.2
    docker build --build-arg BASE_VERSION=$VER -t cslauritsen/sealed-secrets-controller:$VER-csl .
    docker push cslauritsen/sealed-secrets-controller:$VER-csl

# Bootstrapping the Keypair

I've saved the keypair secret YAML in 1password with UID ju6dvpeqhyahzaubummg32erai in the Private vault, currently named rpi kubeseal-key-backup. In order to decrypt existing `SealedSecret` objects, you will need to install it in the cluster: 

    op read "op://Private/ju6dvpeqhyahzaubummg32erai/sealed-secrets-keyj4h5.yaml" | \
     kubectl apply -n kube-system -f -

I think do this before installing the chart, but it might not really matter.

