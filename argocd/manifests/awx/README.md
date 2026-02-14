# AWX Ingress

AWX is hosted outside the rpi cluster so it can more safely be used against the cluster nodes. 

This contains an ingress to route traffic from https://awx.home.planetlauritsen.com to an ExternalName service pointing to AWX on wmini.planetlauritsen.com:8052. It is protected behind oauth2-proxy and requires authentication to access.
