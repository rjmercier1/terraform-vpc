# terraform-vpc
Simple terraform vpc scripts for aws and gcp, including private subnet with external routing (without paid nat gateways!)

You will need to run ssh-keygen to generate appropriate key files before attempting to deploy the vpc.  Also, of course you will need credentials at aws and/or google.

Google's analog to a vpc is their 'network' object, in terraform the resource is "google_compute_network".  You will need to manually create a project using the google gcp platform and update terraform.tfvars.
