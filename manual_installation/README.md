# Manual steps

This document describes the manual steps for creating a TFE active/active cluster behind an application load balancer which you can then connect to over the internet. The TFE is in a private subnet

See below diagram for how the setup is:
![](../diagram/diagram_tfe_active_mode.png)

# Create TFE airgap with loadbalancer single instance
## network
- Create a VPC with cidr block ```10.238.0.0/16```  
![](media/20220912133108.png)  
- Create 4 subnets. 2 public subnets and 2 private subnet
    - patrick-public1-subnet (ip: ```10.238.1.0/24``` availability zone: ```eu-north-1a```)  
    - patrick-public2-subnet (ip: ```10.238.2.0/24``` availability zone: ```eu-north-1b```)  
    - patrick-private1-subnet (ip: ```10.238.11.0/24``` availability zone: ```eu-north-1a```)  
    - patrick-private2-subnet (ip: ```10.238.12.0/24``` availability zone: ```eu-north-1b```)  
![](media/20220912133359.png)    
![](media/20220912133414.png)    
- create an internet gateway and attach to VPC  
![](media/20220912133448.png)   
![](media/20220912133514.png)    
- create a nat gateway which you attach to ```patrick-public1-subnet```   
![](media/20220912133618.png)    
- create routing table for public  
![](media/20220912133707.png)    
   - edit the routing table for internet access to the internet gateway
   ![](media/20220912133804.png)    
- create routing table for private  
   ![](media/20220912133926.png)     
   - edit the routing table for internet access to the nat gateway  
   ![](media/20220912134020.png)     
- attach routing tables to subnets  
    - patrick-public-route to public subnets      
    ![](media/20220912134139.png)       
    - patrick-private-route to private subnet   
     ![](media/20220912134105.png)  
- create a security group that allows  
https   
8800   
port 5432 for PostgreSQL database  
6379 redis
8201 vault
![](media/20220912134534.png)  
- 

## create the RDS postgresql instance
Creating the RDS postgreSQL instance to use with TFE instance

- PostgreSQL instance version 14  
![](media/20220912135024.png)   
![](media/20220912135037.png)    
![](media/20220912135050.png)    
![](media/20220912135110.png)    
![](media/20220912135124.png)    



endpoint: ```patrick-tfe-rds.cvwddldymexr.eu-north-1.rds.amazonaws.com```

# AWS to use
- create a bucket patrick-tfe-manual and patrick-tfe-software
![](media/20220912135225.png)    
![](media/20220912135307.png)  
- upload the following files to patrick-tfe-software
airgap file
license file
bootstrap file


- create IAM policy to access the buckets from the created instance
- create a new policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::patrick-tfe-manual",
                "arn:aws:s3:::patrick-tfe-software",
                "arn:aws:s3:::*/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
}
```

- create a new role  
![](media/20220520124616.png)    
![](media/20220520124635.png)    
![](media/20220520124711.png)    


## closer look
- attach the role to the instance  
![](media/20220510160613.png)  
![](media/20220510104028.png)    
- you should now be able to upload a file to the s3 bucket
```
ubuntu@ip-10-233-1-81:~$ aws s3 cp test.txt s3://patrick-tfe-manual/test.txt
upload: ./test.txt to s3://patrick-tfe-manual/test.txt
```

## certificates
import certificates
![](media/20220520124850.png)    
![](media/20220520124941.png)    
![](media/20220912140552.png)   

# Launch a stepping stone instance

![](media/20220912141116.png)    

# Launch a TFE instance
![](media/20220912142705.png)    
![](media/20220912142652.png)  
![](media/20220912142637.png)    
![](media/20220912142805.png)  
![](media/20220912142819.png)   
![](media/20220912142833.png)  
![](media/20220912142858.png)      
![](media/20220912142913.png)    

Login to the TFE instance and do the following steps

```
apt-get update
apt-get install -y ctop net-tools sysstat

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

apt-get -y install awscli

aws s3 cp s3://patrick-tfe-software/652.airgap /tmp/652.airgap
aws s3 cp s3://patrick-tfe-software/license.rli /tmp/license.rli
aws s3 cp s3://patrick-tfe-software/replicated.tar.gz /tmp/replicated.tar.gz


cat > /tmp/tfe_settings.json <<EOF
{
   "aws_instance_profile": {
        "value": "1"
    },
    "enc_password": {
        "value": "Password#1"
    },
    "hairpin_addressing": {
        "value": "1"
    },
    "hostname": {
        "value": "patrick-tfe4.bg.hashicorp-success.com"
    },
    "pg_dbname": {
        "value": "tfe"
    },
    "pg_netloc": {
        "value": "patrick-manual-tfe.cvwddldymexr.eu-north-1.rds.amazonaws.com"
    },
    "pg_password": {
        "value": "Password#1"
    },
    "pg_user": {
        "value": "postgres"
    },
    "placement": {
        "value": "placement_s3"
    },
    "production_type": {
        "value": "external"
    },
    "s3_bucket": {
        "value": "patrick-tfe-manual"
    },
    "s3_endpoint": {},
    "s3_region": {
        "value": "eu-north-1"
    }
}
EOF

cat > /etc/replicated.conf <<EOF
{
    "DaemonAuthenticationType":          "password",
    "DaemonAuthenticationPassword":      "Password#1",
    "TlsBootstrapType":                  "self-signed",
    "TlsBootstrapHostname":              "patrick-tfe4.bg.hashicorp-success.com",
    "BypassPreflightChecks":             true,
    "ImportSettingsFrom":                "/tmp/tfe_settings.json",
    "LicenseFileLocation":               "/tmp/license.rli",
    "LicenseBootstrapAirgapPackagePath": "/tmp/652.airgap"
}
EOF

# directory for decompress the file
sudo mkdir -p /opt/tfe
pushd /opt/tfe
sudo tar xzf /tmp/replicated.tar.gz

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
echo ${LOCAL_IP}

sudo bash ./install.sh airgap private-address=${LOCAL_IP}



```

# Load balancer
Create loadbalancer target groups for port 443 and 8800  
![](media/20220912153506.png)    

create a loadbalancer application pointing to the target groups

 ![](media/20220912153536.png)   


# result

You should have a working TFE environment at this point that you can login to and have a workspace

![](media/20220912154955.png)    



# Active Active

Get a elasticache Redis environment
![](media/20220912155231.png)    

![](media/20220912155647.png)    
![](media/20220912155656.png)    
![](media/20220912155705.png)    
![](media/20220912155716.png)    
![](media/20220912155726.png)    
![](media/20220912155737.png)    
![](media/20220912155803.png)    
![](media/20220912155819.png)    


# test connection to Redis

https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/GettingStarted.ConnectToCacheNode.html

patrick-example.1yhbvq.0001.eun1.cache.amazonaws.com:6379
sudo apt install redis-server

redis-cli -h patrick-example.1yhbvq.0001.eun1.cache.amazonaws.com -c -p 6379



###


```
apt-get update
apt-get install -y ctop net-tools sysstat

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

apt-get -y install awscli

aws s3 cp s3://patrick-tfe-software/652.airgap /tmp/652.airgap
aws s3 cp s3://patrick-tfe-software/license.rli /tmp/license.rli
aws s3 cp s3://patrick-tfe-software/replicated.tar.gz /tmp/replicated.tar.gz





cat > /tmp/tfe_settings.json <<EOF
{
   
   "aws_instance_profile": {
        "value": "1"
    },
   "enable_active_active" : {
    "value": "1"
    },
    "enc_password": {
        "value": "Password#1"
    },
    "hairpin_addressing": {
        "value": "1"
    },
    "hostname": {
        "value": "patrick-tfe4.bg.hashicorp-success.com"
    },
    "pg_dbname": {
        "value": "tfe"
    },
    "pg_netloc": {
        "value": "patrick-manual-tfe.cvwddldymexr.eu-north-1.rds.amazonaws.com"
    },
    "pg_password": {
        "value": "Password#1"
    },
    "pg_user": {
        "value": "postgres"
    },
    "placement": {
        "value": "placement_s3"
    },
    "production_type": {
        "value": "external"
    },
    {
  "redis_host" : {
    "value": "patrick-tfe-manual.1yhbvq.ng.0001.eun1.cache.amazonaws.com:6379"
  },
  "redis_port" : {
    "value": "6379"
  },
  "redis_use_password_auth" : {
    "value": "0"
  },
  "redis_pass" : {
    "value": "somepassword"
  },
  "redis_use_tls" : {
    "value": "1"
  }
    "s3_bucket": {
        "value": "patrick-tfe-manual"
    },
    "s3_endpoint": {},
    "s3_region": {
        "value": "eu-north-1"
    }
}
EOF

cat > /etc/replicated.conf <<EOF
{
    "DaemonAuthenticationType":          "password",
    "DaemonAuthenticationPassword":      "Password#1",
    "TlsBootstrapType":                  "self-signed",
    "TlsBootstrapHostname":              "patrick-tfe4.bg.hashicorp-success.com",
    "BypassPreflightChecks":             true,
    "ImportSettingsFrom":                "/tmp/tfe_settings.json",
    "LicenseFileLocation":               "/tmp/license.rli",
    "LicenseBootstrapAirgapPackagePath": "/tmp/652.airgap"
}
EOF

# directory for decompress the file
sudo mkdir -p /opt/tfe
pushd /opt/tfe
sudo tar xzf /tmp/replicated.tar.gz

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
echo ${LOCAL_IP}

sudo bash ./install.sh airgap private-address=${LOCAL_IP}



```




































## Auto-launch scaling group
- Auto Scaling - Launch Configurations  
![](media/20220520125432.png)  
- Create launch configuration. 
![](media/20220520125530.png)  
![](media/20220520125655.png)    
```
#!/bin/bash

# Download all the software and files needed
aws s3 cp s3://patrick-tfe-software/610.airgap /tmp/610.airgap
aws s3 cp s3://patrick-tfe-software/license.rli /tmp/license.rli
aws s3 cp s3://patrick-tfe-software/replicated.tar.gz /tmp/replicated.tar.gz

# directory for decompress the file
sudo mkdir -p /opt/tfe
pushd /opt/tfe
sudo tar xzf /tmp/replicated.tar.gz


cat > /tmp/tfe_settings.json <<EOF
{
   "aws_instance_profile": {
        "value": "1"
    },
    "enc_password": {
        "value": "Password#1"
    },
    "hairpin_addressing": {
        "value": "1"
    },
    "hostname": {
        "value": "patrick-tfe.bg.hashicorp-success.com"
    },
    "pg_dbname": {
        "value": "tfe"
    },
    "pg_netloc": {
        "value": "patrick-manual-tfe.cvwddldymexr.eu-north-1.rds.amazonaws.com"
    },
    "pg_password": {
        "value": "Password#1"
    },
    "pg_user": {
        "value": "postgres"
    },
    "placement": {
        "value": "placement_s3"
    },
    "production_type": {
        "value": "external"
    },
    "s3_bucket": {
        "value": "patrick-tfe-manual"
    },
    "s3_endpoint": {},
    "s3_region": {
        "value": "eu-north-1"
    }
}
EOF


# replicated.conf file
cat > /etc/replicated.conf <<EOF
{
    "DaemonAuthenticationType":          "password",
    "DaemonAuthenticationPassword":      "Password#1",
    "TlsBootstrapType":                  "self-signed",
    "TlsBootstrapHostname":              "patrick-tfe.bg.hashicorp-success.com",
    "BypassPreflightChecks":             true,
    "ImportSettingsFrom":                "/tmp/tfe_settings.json",
    "LicenseFileLocation":               "/tmp/license.rli",
    "LicenseBootstrapAirgapPackagePath": "/tmp/610.airgap"
}
EOF

# Following manual:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
echo ${LOCAL_IP}

sudo bash ./install.sh airgap private-address=${LOCAL_IP}




````
![](media/20220520132657.png)    
![](media/20220520132720.png)    
![](media/20220520132750.png)    
![](media/20220520132810.png)    
- The launch configuration should now be visible  
![](media/20220520132828.png)  


- loadbalancer create a target group which we at a later point connect to the Auto Scaling Group  
 ![](media/20220520133657.png)  
 ![](media/20220520133733.png)    
- Will have no targets yet  
![](media/20220520133755.png)    

- do the same for the tfe-app port 443

- loadbalancer create a appplication load balancer which will connect to the load balancer target    
![](media/20220520133950.png)    
- following configuration  
![](media/20220520134014.png)  
![](media/20220520134040.png)    
![](media/20220520134059.png)    
![](media/20220520134138.png)    
![](media/20220520134318.png)    
![](media/20220520134341.png)    


- Auto Scaling groups. Will configure the group and connect it to auto scaling launch and the created load balancer
Make sure you switch to launch configuration   
![](media/20220520134600.png)    
![](media/20220520134625.png)    
![](media/20220520134702.png)    
![](media/20220520134759.png)    
![](media/20220520134837.png)    
![](media/20220520134852.png)    
![](media/20220520134913.png)      

- You should now see an instance being started   
![](media/20220412113300.png)       


- Alter the DNS record in route53 to point to the loadbalancer dns name    
![](media/20220520134508.png)  
- You should now be able to connect to your website   


### Test the autoscaling

After everything is working you should see one web server running and one web server as a target in the load balancer target group

EC2   
![](media/20220412113820.png)    

Load balancer target  
![](media/20220412113839.png)    

**Change the Auto scaling group to have 2 servers**
- Edit your Auto scaling group  
- Change the desired capacity to 2  
![](media/20220412113904.png)    

- After that you should see 2 EC2 instances and load balancer target with 2 instances    
![](media/20220412114410.png)  























- Auto Scaling groups. Will configure the group and connect it to auto scaling launch and the created load balancer  


- loadbalancer generated a DNS name which you can use to connect to the application server  


### Test the autoscaling

After everything is working you should see one TFE running. If you terminate the instance a new one will be created and can be used. 