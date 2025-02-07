################################################  
## DAY 1: PRE-REQ                             ##  
################################################  
##  
##  
- docker installed.  
- ansible installed (if possible all module or install ansible-galaxy collection install community.aws as the playbook uses some aws modules e.g: ansible-galaxy collection install community.aws ).  
- terraform installed.  
- configure your terminal with aws configure or if not you may need to do some IAM prep works for you (using assume role which is not part of this tutorial)(considering this is your day 0/1 for the project) I mean no sarcastic but you need admin privilege account in the beginning right?  
- create secrets in secret manager in AWS, prefer manual in console or aws cli for security reason you dont want this always automated or part of terraform, believe me, been there, not even backend remote of tfstate can save you in audit...so... IMHO on this step needs human element > create secret manager in aws console/cli.  
    > e.g: aws secretsmanager create-secret --name <secretnamehere> --secret-string "{\"username\":\"<userhere>\",\"password\":\"<passwordhere>\",\"database\":\"<dbnamehere>\"}" --endpoint-url=http://localhost:4566  #please ignore endpoint i am using localstack during development
- create ecr repos for docker images, name should be align to you app name declared
#  
#  
# change values in tfsource before running below  
- chmod +x ./prereq-checker.sh  
- sh ./prereq-checker.sh  
- source tfsource
#  
#  
# infra provisioning  
- terraform fmt  
- terraform validate  
- terraform plan  
- terraform apply  
# continous delivery setup  
- cd cd  
- terraform fmt  
- terraform validate  
- terraform plan  
- terraform apply   

#################################################
## DAY 2: BAU                                  ##
#################################################  
???